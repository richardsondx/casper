# casper_runner.rb

require 'yaml'

# Configuration
PROFILE = '~/.test_profile' # Change this to the desired shell profile
CASPER_FUNCTION_SUFFIX = '_casper'
ALERT_TYPE = :log # Change this to :log, :http_request, or :slack based on the desired alert method
LOG_BACKTRACE = true # Change this to false to disable logging of backtrace

def set_error_tracker(function_name = nil)
  yaml_file = 'casperconfig.yaml'

  File.open(yaml_file, 'r+') do |file|
    config = YAML.safe_load(file.read)

    if config['plugins'].nil? || config['plugins'].empty?
      puts "Error: No plugins defined in #{yaml_file}. Cannot set error_tracker."
      exit 1
    end

    plugins_to_install = []

    if function_name.nil?
      # If no function name is provided, install every plugin command
      config['plugins'].each do |plugin|
        plugin['commands'].each do |command|
          new_function_name = "#{command}#{CASPER_FUNCTION_SUFFIX}"
          plugins_to_install << [new_function_name, plugin['name'], command]
        end
      end
    else
      # If function name is provided, install only the specified command
      config['plugins'].each do |plugin|
        plugin['commands'].each do |cmd|
          if cmd == function_name
            new_function_name = "#{function_name}#{CASPER_FUNCTION_SUFFIX}"
            plugins_to_install << [new_function_name, plugin['name'], cmd]
          end
        end
      end
    end

    if plugins_to_install.empty?
      puts "Error: No matching function name found in the casperconfig.yaml file."
      exit 1
    end

    plugins_to_install.each do |function_name, plugin_name, command|
      puts "Adding error_tracker to #{function_name}"
      File.write(yaml_file, YAML.dump(config).gsub(command, function_name))
      add_casper_command(plugin_name, function_name, command)
    end
  end
end

def unset_error_tracker(function_name)
  yaml_file = 'casperconfig.yaml'
  new_function_name = "#{function_name}#{CASPER_FUNCTION_SUFFIX}"

  File.open(yaml_file, 'r+') do |file|
    config = YAML.safe_load(file.read)

    if config['plugins'].nil? || config['plugins'].empty?
      puts "Error: No plugins defined in #{yaml_file}. Cannot unset error_tracker."
      exit 1
    end

    config['plugins'].each do |plugin|
      plugin_name = plugin['name']
      plugin['commands'].each do |command|
        if command == new_function_name
          puts "Removing error_tracker from #{function_name}"
          File.write(yaml_file, YAML.dump(config).gsub(new_function_name, function_name))
          remove_casper_command(plugin_name, new_function_name)  # Fixed here
          return
        end
      end
    end

    puts "Error: Function '#{new_function_name}' not found in the casperconfig.yaml file."
    exit 1
  end
end


def add_casper_command(plugin_name, function_name, command)
  profile_path = File.expand_path(PROFILE)
  profile_content = File.read(profile_path)

  new_function_name = "#{function_name}"

  casper_command = <<-SHELL
#{new_function_name}() {
  # Error tracking logic before the original command
  track_error("#{plugin_name}", "#{command}", "$*")

  # Call the original command with its arguments
  command #{command} "$@"

  # Error tracking logic after the original command
  track_error_complete("#{command}", "$*")
}
SHELL

  casper_block_start = profile_content.index(/(#+\s*)CASPER START/)
  casper_block_end = profile_content.index(/(#+\s*)CASPER END/)

  if casper_block_start && casper_block_end && casper_block_start < casper_block_end
    casper_block_content = profile_content[/#+\s*CASPER START\s*(.*?)\s*#+\s*CASPER END/m, 1]
  else
    # Add the casper_block to the profile content if it's not there
    profile_content << "\n################## CASPER START\n\n################## CASPER END\n"
    casper_block_content = ""
  end

  # Check if the casper_command already exists in the casper_block
  unless casper_block_content.include?(casper_command)
    # Replace the CASPER block with new block content
    new_casper_block = <<-SHELL
################## CASPER START
#{casper_command}
#{casper_block_content.strip}
################## CASPER END
SHELL

    profile_content.gsub!(/################## CASPER START.*################## CASPER END/m, new_casper_block.strip)
    File.write(profile_path, profile_content)

    puts "Casper command added to #{PROFILE}"
  else
    puts "Casper command already exists in #{PROFILE}. No need to add again."
  end
end

def remove_casper_command(plugin_name, function_name)
  profile_path = File.expand_path(PROFILE)
  profile_content = File.read(profile_path)

  new_function_name = "#{function_name}"

  casper_block_start = profile_content.index(/(#+\s*)CASPER START/)
  casper_block_end = profile_content.index(/(#+\s*)CASPER END/)

  if casper_block_start && casper_block_end && casper_block_start < casper_block_end
    casper_block_content = profile_content[casper_block_start..casper_block_end]

    # Capture entire function body including brackets {}
    function_regex = /(#{new_function_name}\(\) \{[^}]*\})/

    if casper_block_content.match(function_regex)
      # Remove the function
      casper_block_content.gsub!(function_regex, '')

      # Replace the old CASPER block with the new block in the profile content
      profile_content[casper_block_start..casper_block_end] = casper_block_content

      File.write(profile_path, profile_content)
      puts "Casper command #{new_function_name} removed from #{PROFILE}"
    else
      puts "Error: Casper command '#{new_function_name}' not found in #{PROFILE}. Cannot remove Casper commands."
    end
  else
    puts "Error: CASPER START and CASPER END comments not found in #{PROFILE}. Cannot remove Casper commands."
  end
end

def get_device_info
  # Implement the logic to get device information
  # You can use Ruby or any system command to gather device info
  # For example, using Ruby's `Socket` module to get the hostname and OS
  require 'socket'

  hostname = Socket.gethostname
  os_version = `sw_vers -productVersion`.strip # macOS version

  "Device: #{hostname}, macOS #{os_version}"
end

def track_error_complete(command, error_message)
  case ALERT_TYPE
  when :log
    log_error(command, error_message)
  when :http_request
    send_http_request(command, error_message)
  when :slack
    send_slack_message(command, error_message)
  else
    puts "Error: Invalid ALERT_TYPE specified in the casper_runner.rb script."
  end
end

def log_error(command, error_message)
  # Implement the logic to log the error in a log.txt file

  # Command execution status code (0 means success, non-zero means error)
  command_status = $?

  if command_status.exitstatus != 0
    puts "Command '#{command}' triggered an error at: #{Time.now}"
    puts "Error Message: #{error_message}"

    error_message_with_backtrace = "Command '#{command}' triggered an error at: #{Time.now}\nError Message: #{error_message}\nBacktrace:\n#{caller.join("\n")}"

    if LOG_BACKTRACE
      puts error_message_with_backtrace
      File.open('log.txt', 'a') { |file| file.puts(error_message_with_backtrace) }
    else
      File.open('log.txt', 'a') { |file| file.puts("Command '#{command}' triggered an error at: #{Time.now}\nError Message: #{error_message}") }
    end
  end
end

def send_http_request(command, error_message)
  # Implement the logic to make an HTTP request to an endpoint
  # Example: Use Ruby's Net::HTTP to send a request with the error information
end

def send_slack_message(command, error_message)
  # Implement the logic to send a Slack message to a channel
  # Example: Use a Slack API or gem to post a message in a specified channel
  # Note: You'll need to configure your Slack credentials and the desired channel
  # For simplicity, this is just a placeholder message
  puts "Slack message sent: Error occurred at #{Time.now}"
end



action = ARGV[0]
function_name = ARGV[1]

case action
when 'set'
  set_error_tracker(function_name)
when 'unset'
  unset_error_tracker(function_name)
else
  puts "Usage: ruby casper_runner.rb set <function_name> or ruby casper_runner.rb unset <function_name>"
end