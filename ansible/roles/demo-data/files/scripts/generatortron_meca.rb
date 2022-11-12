module Generatortron
  module Errors
    class GeneratortronError < RuntimeError; end
    class RecordNotSaved < GeneratortronError
      def message
        record = super
        descriptor = "#{record.class.name} #{record.name}"
        errors = record.errors.full_messages.to_sentence
        "Error saving #{descriptor}: #{errors}: #{record.attributes.to_json}"
      end
    end
  end

  class Generator
    attr_reader :errors

    def initialize(data_path)
      @errors = []
      @data_path = data_path
    end

    def call
      if data[:inferred_metrics]
        InferredMetric.destroy_all
        data[:inferred_metrics].each do |metric_data|
          create_inferred_metric(metric_data)
        end
      end
    end

    def valid?
      @errors.clear
      validate!
      @errors.empty?
    end

    def validate!
      @errors << "data file not found" unless File.exist?(@data_path)
    end

    private

    def data
      @data ||= YAML.load_file(@data_path).with_indifferent_access
    end

    def create_inferred_metric(data)
      params = data.slice(:name, :unit, :formula, :tag, :metric_type).with_indifferent_access
      data[:sources].each_with_index do |src, idx|
        letter = idx == 0 ? 'a' : 'b'
        type = src[:type]
        params["source_#{letter}_type"] = type
        params["#{type.downcase}_#{letter}_id"] = src[:name]
      end
      data[:keys].each do |key_data|
        params["keys"] ||= {}.with_indifferent_access
        h = {
          "source" => key_data[:source],
          "metric" => key_data[:metric],
        }
        params["keys"][key_data[:key]] = h
      end
      metric = InferredMetric.new(params.with_indifferent_access)
      if metric.save_and_validate_formula
        puts "-> Created #{data[:metric_type]} metric #{data[:name]}"
      else
        raise Errors::RecordNotSaved, metric
      end
    end
  end

  def self.usage
    $stderr.puts "Usage: $0 FILE"
    $stderr.puts
    $stderr.puts "Create racks and devices specified in FILE"
    $stderr.puts
    $stderr.puts "FILE is a YAML formatted file specifying the racks and devices create"
  end

  def self.connect_to_romance
    require 'romance/consumer'
    Romance.listen('GeneratortronMeca')
    attempts = 0
    max_attempts = 50
    loop do
      begin
        break if Group
      rescue NameError
        attempts += 1
        if attempts > max_attempts
          raise Generatortron::Errors::GeneratortronError, "unable to romance Group"
        end
        sleep 0.5
      end
    end
    true
  end

  def self.main(args)
    if args.length != 1
      usage
      return 1
    end
    begin
      # InferredMetric.new requires romanced `Group` and/or `Device` models.
      connect_to_romance
      generator = Generator.new(args.first)
      if generator.valid?
        generator.call
        return 0
      else
        $stderr.puts generator.errors.join(", ")
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

code = Generatortron.main(ARGV)
exit code || 0
