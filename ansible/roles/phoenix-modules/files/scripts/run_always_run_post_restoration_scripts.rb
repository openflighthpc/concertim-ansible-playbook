#!/usr/bin/env ruby1.8

require 'yaml'

# XXX Move this to a gem.
$:.unshift("/opt/concurrent-thinking/sas/lib")
require 'open_wait'


def run_command(scripts_dir, file)
  log("Running always run post restoration file #{file.inspect}")
  abspath = File.join(scripts_dir, file)
  status = OpenWait.popen3(abspath) do |stdin, stdout, stderr|
    log(stdout.read)
    log(stderr.read, $stderr)
  end
  status.exitstatus == 0
end


def log(msg, io=$stdout)
  io.puts(msg)
end


def ordered_files_to_run(scripts_dir)
  Dir.entries(scripts_dir).reject do |f|
    invalid_file_name?(f) || ! File.executable?(File.join(scripts_dir, f)) 
  end.sort.each do |f|
    yield f
  end
end


def invalid_file_name?(file_name)
  return true if file_name.end_with?("~")
  return true if file_name.end_with?(".swp")
  return true if file_name.end_with?(".swo")
  return true unless file_name =~ /^\d{3}/
  return false
end


def main(scripts_dir)
  ordered_files_to_run(scripts_dir) do |file|
    unless run_command(scripts_dir, file)
      raise "Running always run post restoration script #{file.inspect} failed"
    end
  end
end


if __FILE__ == $0
  begin
    scripts_dir = ARGV[0]
    main(scripts_dir)
    exit 0
  rescue
    log($!.message, $stderr)
    #  log($!.backtrace.join("\n"), $stderr)
    exit 1
  end
end
