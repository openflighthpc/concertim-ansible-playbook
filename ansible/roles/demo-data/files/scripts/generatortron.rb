module Generatortron
  module Errors
    class GeneratortronError < RuntimeError; end
    class RecordNotSaved < GeneratortronError
      def message
        record = super
        descriptor = "#{record.class.name} #{record.name}"
        errors = record.errors.full_messages.to_sentence
        "Error saving #{descriptor}: #{errors}: #{record.attributes}"
      end
    end
    class EmptySlotNotFound < GeneratortronError
      def message
        record = super
        descriptor = "#{record.class.name} #{record.name}"
        errors = "unable to find empty slot"
        "Error saving device in #{descriptor}: #{errors}"
      end
    end
  end

  class Generator
    extend ActiveModel::Naming

    attr_reader :errors

    class << self
      def human_attribute_name(attr, options = {})
        attr
      end

      def lookup_ancestors
        [self]
      end
    end

    def initialize(data_path)
      @errors = ActiveModel::Errors.new(self)
      @data_path = data_path
      @cluster = Cluster.first
    end

    def call
      data[:sensors].each do |sensor_data|
        # Ivy::Chassis#get_default_name assumes that two chassis would never
        # be created in the same second.  We need to honour that.
        sleep 1
        create_sensor(sensor_data)
      end

      data[:racks].each do |rack_data|
        rack = create_rack(rack_data)

        if HwRack.count == 1
          # Ivy::Chassis#get_default_name assumes that two chassis would never
          # be created in the same second.  We need to honour that.
          sleep 1
          create_management_appliance(rack)
          Ivy::Group::RuleBasedGroup.adjust_role_groups
        end

        rack_data[:zero_u_devices].each do |device_data|
          # Ivy::Chassis#get_default_name assumes that two chassis would never
          # be created in the same second.  We need to honour that.
          sleep 1
          create_zero_u_device(rack, device_data)
        end
        rack_data[:devices].each do |device_data|
          # Ivy::Chassis#get_default_name assumes that two chassis would never
          # be created in the same second.  We need to honour that.
          sleep 1
          chassis = create_rack_device(rack, device_data)
          next unless device_data[:devices]

          device_data[:devices].each do |chassis_server_data|
            # Ivy::Chassis#get_default_name assumes that two chassis would never
            # be created in the same second.  We need to honour that.
            sleep 1
            create_chassis_server(chassis, chassis_server_data)
          end
        end
      end
    end

    def valid?
      @errors.clear
      validate!
      @errors.empty?
    end

    def validate!
      @errors.add(:data, "file not found") unless File.exist?(@data_path)
      @errors.add(:cluster, "not found") if @cluster.nil?
      @errors.add(:racks, "racks key not present in data file") if data[:racks].nil?
    end


    def read_attribute_for_validation(attr)
      case attr
      when :data
        data
      when :cluster
        @cluster
      else
        data[attr]
      end
    end

    private

    def data
      @data ||= YAML.load_file(@data_path).with_indifferent_access
    end

    def create_rack(data)
      rack = Ivy::HwRack.find_by_name(data[:name])
      if rack
        puts "Found rack #{rack.name}"
        return rack
      end

      params = {
        :name => data[:name],
        :u_height => data[:u_height] || 20,
        :template_id => data[:template_id],
        :cluster_id => @cluster_id,
      }
      rack = Ivy::HwRackServices::Create::call(params, "generatortron")

      if rack.persisted?
        puts "Created rack #{rack.name}"
      else
        raise Errors::RecordNotSaved, rack
      end

      rack
    end

    def create_management_appliance(rack)
      device = Ivy::Device.find_by_role('mia')
      if device
        puts "-> Found MIA #{device.name}"
        return
      end

      params = management_appliance_params(rack)
      res = Ivy::TemplatePersister.persist_one_with_changes(params)
      if res[:success] && res[:chassis] && res[:chassis].device
        res[:chassis].device.update_attribute(:role, 'mia')
        puts "-> Created MIA #{nice_log_name(nil, res)}"
      elsif !res[:success]
        raise Errors::RecordNotSaved, res[:failed_objs].first
      else
        raise Errors::GeneratortronError, "unexpected failure when creating MIA"
      end
    end

    def management_appliance_params(rack)
      template_id = 385
      template = Ivy::Template.find(template_id)
      {
        "chassis" => {
          "u_height" => template.height,
          "u_depth" => template.depth,
          "facing" => "f",
          "rack_id" => rack.id,
          "rack_start_u" => rack.u_height,
        },

        "devices" => {
          "name" => "command",
          "type" => "ManagedDevice",
          "template_id" => template_id,
        }
      }.with_indifferent_access
    end

    def create_zero_u_device(rack, data)
      device = Ivy::Device.find_by_name(data[:name])
      if device
        puts "-> Found zero u device #{device.name}"
        return
      end

      params = zero_u_device_params(rack, data)
      res = Ivy::TemplatePersister.persist_one_with_changes(params)
      if res[:success]
        puts "-> Created zero u device #{nice_log_name(data, res)}"
      else
        raise Errors::RecordNotSaved, res[:failed_objs].first
      end
    end

    def zero_u_device_params(rack, data)
      start_u =
        case data[:location]
        when 'top'
          rack.u_height
        when 'middle'
          (rack.u_height / 2).to_i
        else
          1
        end

      {
        "chassis" => {
          "u_height" => 0,
          "u_depth" => 1,
          "facing" => data[:facing],
          "rack_id" => rack.id,
          "rack_start_u" => start_u,
          "zerou" => true,
        },

        "devices" => {
          "name" => data[:name],
          "type" => data[:type],
          "template_id" => data[:template_id],
          "username" => data[:username],
          "password" => data[:password],
        }
      }.with_indifferent_access
    end

    def create_rack_device(rack, data)
      device = Ivy::Device.find_by_name(data[:name])
      if device
        puts "-> Found rack device #{device.name}"
        return
      end

      params = rack_device_params(rack, data)
      res = Ivy::TemplatePersister.persist_one_with_changes(params)
      if res[:success]
        puts "-> Created rack device #{nice_log_name(data, res)}"
      else
        raise Errors::RecordNotSaved, res[:failed_objs].first
      end

      return res[:chassis]
    end

    def rack_device_params(rack, data)
      template = Ivy::Template.find(data[:template_id])

      {
        "chassis" => {
          "u_height" => template.height,
          "u_depth" => template.depth,
          "facing" => data[:facing],
          "rack_id" => rack.id,
          "rack_start_u" => data[:start_u],
        },

        "devices" => {
          "name" => data[:name],
          "type" => data[:type],
          "template_id" => data[:template_id],
        }
      }.with_indifferent_access
    end

    def create_chassis_server(chassis, data)
      server = chassis.devices.find_by_name(data[:name])
      if server
        puts "--> Found chassis server #{server.name}"
        return
      end

      params = chassis_server_params(chassis, data)
      server = Ivy::Device::Server.create(params)
      if server.persisted?
        puts "--> Created chassis server #{server.name}"
      else
        raise Errors::RecordNotSaved, server
      end
    end

    def chassis_server_params(chassis, data)
      chassis.reload
      # FSR `chassis.slots` doesn't work correctly when the chassis has just
      # been created. So we have to do this the long way.
      slots = chassis.chassis_rows.map(&:slots).flatten
      empty_slot = slots.detect { |s| s.device.nil? }
      raise Errors::EmptySlotNotFound, chassis unless empty_slot

      {
        "name" => data[:name],
        "type" => data[:type],
        "template_id" => data[:template_id],
        "slot_id" => empty_slot.id,
      }.with_indifferent_access
    end

    def create_sensor(data)
      device = Ivy::Device.find_by_name(data[:name])
      if device
        puts "-> Found sensor #{device.name}"
        return
      end

      params = sensor_params(data)
      res = Ivy::TemplatePersister.persist_one_with_changes(params)
      if res[:success]
        puts "-> Created #{data[:sensor_type]} sensor #{nice_log_name(data, res)}"
      else
        raise Errors::RecordNotSaved, res[:failed_objs].first
      end
    end

    def sensor_params(data)
      {
        "chassis" => {
          "nonrack" => true,
        },
        "devices" => {
          "name" => data[:name],
          "type" => "Sensor",
          "template_id" => data[:template_id],
          "stype" => data[:sensor_type],
        }
      }.with_indifferent_access
    end

    def nice_log_name(data, res)
      chassis = res[:chassis]
      chassis_name = chassis.nil? ? nil : chassis.name
      device = chassis.nil? ? nil : chassis.device
      device_name = device.nil? ? nil : device.name
      data_name = data.nil? ? nil : data[:name]

      return device_name unless device_name.blank?
      return data_name unless data_name.blank?
      return chassis_name unless chassis_name.blank?
      "<UNKNOWN>"
    end
  end

  def self.usage
    $stderr.puts "Usage: $0 FILE"
    $stderr.puts
    $stderr.puts "Create racks and devices specified in FILE"
    $stderr.puts
    $stderr.puts "FILE is a YAML formatted file specifying the racks and devices create"
  end

  def self.main(args)
    if args.length != 1
      usage
      return 1
    end
    begin
      generator = Generator.new(args.first)
      if generator.valid?
        generator.call
        return 0
      else
        $stderr.puts generator.errors.full_messages
        return 1
      end
    rescue Generatortron::Errors::GeneratortronError
      $stderr.puts $!.message
      return 1
    rescue
      $stderr.puts $!
      $stderr.puts $!.message
      $stderr.puts $!.backtrace
      return 2
    end
  end
end

if __FILE__ == $0
  code = Generatortron.main(ARGV)
  exit code || 0
end
