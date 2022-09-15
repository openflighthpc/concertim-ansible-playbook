#!/usr/bin/env ruby1.8

class MySetupManagerAutomator < SetupManagerAutomator

  attr_reader :setup_manager

  def wait_for_threaded_threads
    until setup_manager_in_terminal_state? || !!@failed || !!@completed
      sleep 2
    end
  end

  def run
    super
    wait_for_threaded_threads
  end

  def failed(msg)
    @failed = true
    super
  end

  def completed_callback
    @completed = true
    super
  end

  private

  def setup_manager_in_terminal_state?
    %w(failed completed operational).include?(@setup_manager.state.to_s)
  end

  def test_secure_interface_callback
    @setup_manager.send_event(:fail)
    @setup_manager.send_event(:force)
  end
end

# Configure the automator and run it.
class AutomatorRunner
  def initialize
    # @monitor = Monitor.new
    # @threaded_threads = []
    setup_data = YAML.load_file("/usr/src/concurrent-thinking/setup-data.yml")
    @automator = MySetupManagerAutomator.new(
      :setup_data => setup_data,
      :log_method => method(:log),
      # :onchange_callback => method(:log),
      # :completed_callback => method(:log),
      :failure_callback => method(:failure_callback)
    )
  end

  def call
    untar_appliance_config
    @automator.send(:initialize_setup_manager)
    @automator.setup_manager.reset!
    @automator.run
  end

  def untar_appliance_config
    cmd = "cd /usr/src/concurrent-thinking ; sudo tar xzf appliance-config.tgz ; sudo tar xzf security-pack.tgz"
    system(cmd)
  end

  def log(msg)
    ::STDERR.puts(msg)
  end

  def failure_callback(msg)
    log(msg)
    @automator.setup_manager.reset!
  end
end

AutomatorRunner.new.call
