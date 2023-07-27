require 'yaml'

# Configuration
PROFILE = '~/.test_profile' # Change this to the desired shell profile
LOG_FILE= '~/casper_log.txt'
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
          new_function_name = "#{command}"
          plugins_to_install << [new_function_name, plugin['name'], command]
        end
      end
    else
      # If function name is provided, install only the specified command
      config['plugins'].each do |plugin|
        plugin['commands'].each do |cmd|
          if cmd == function_name
            new_function_name = "#{function_name}"
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

def unset_error_tracker(function_name = nil)
  profile_path = File.expand_path(PROFILE)
  profile_content = File.read(profile_path)

  if function_name.nil?
    clear_all_functions
  else
    if profile_content.include?(function_name)
      puts "Removing error_tracker from #{function_name}"
      remove_casper_command(function_name)
    else
      puts "Error: Function '#{function_name}' not found in the test_profile file."
      exit 1
    end
  end
end

def set_casper_in_profile
  profile_path = File.expand_path(PROFILE)
  profile_content = File.read(profile_path)

  # Check if casper_track_error is already defined in the profile content
  unless profile_content.include?('casper_track_error() {')
    # Inject the casper_track_error function at the end of the profile content
    casper_track_error_code = <<-SHELL
casper_track_error() {
    echo "casper_track_error called"

    local exit_code="$1"
    local os_version="$2"
    local command_run="$3"
    local output="$4"
    local error_message="$5"
    local log_file="#{LOG_FILE}"
    
    log_file=$(eval echo "$log_file")

    # Check if the log file exists; create it if it doesn't
    if [ ! -f "$log_file" ]; then
        touch "$log_file"
    fi

    # Add a timestamp similar to Rails log timestamp
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Save the error message and backtrace (output) to the log file
    {
        echo "[$timestamp] OS Version: $os_version"
        echo "[$timestamp] Command: $command_run"
        echo "[$timestamp] Exit Code: $exit_code"
        echo "[$timestamp] $error_message"
        #{LOG_BACKTRACE ? 'echo "[$timestamp] Backtrace:"' : ''}
        #{LOG_BACKTRACE ? 'echo "[$timestamp] $output"' : ''}
        echo ""
    } >> "$log_file"
}
SHELL

    profile_content += "\n\n" + casper_track_error_code
    File.write(profile_path, profile_content)

    puts "casper_track_error function injected into the profile: #{PROFILE}"
  else
    puts "casper_track_error function is already defined in the profile: #{PROFILE}"
  end
end


def clear_all_functions
  profile_path = File.expand_path(PROFILE)
  profile_content = File.read(profile_path)
  
  casper_block_start = profile_content.index(/#+\s*CASPER START/)
  casper_block_end = profile_content.index(/#+\s*CASPER END/)

  if casper_block_start && casper_block_end && casper_block_start < casper_block_end
    profile_content.slice!(casper_block_start..casper_block_end)

    File.write(profile_path, profile_content)
    puts "Casper commands removed from #{PROFILE}"
  else
    puts "Error: CASPER START and CASPER END comments not found in #{PROFILE}. Cannot remove Casper commands."
  end
end

def clear_yaml
  yaml_file = 'casperconfig.yaml'

  File.open(yaml_file, 'r+') do |file|
    config = YAML.safe_load(file.read)

    if config['plugins'].nil? || config['plugins'].empty?
      puts "Error: No plugins defined in #{yaml_file}. Cannot unset error_tracker."
      exit 1
    end

    config['plugins'].each do |plugin|
      plugin['commands'] = []
    end

    # Write the updated configuration back to the YAML file
    File.write(yaml_file, YAML.dump(config))
  end
end


def add_casper_command(plugin_name, function_name, command)
  set_casper_in_profile

  profile_path = File.expand_path(PROFILE)
  profile_content = File.read(profile_path)

  new_function_name = "casper_#{function_name}"

  casper_command = <<-SHELL
  #{function_name}() {
    #{new_function_name}() {
      echo "👻 Casper is watching and tracking errors for: #{function_name}..."
  
      # Run docker-compose and capture both stdout and stderr to separate variables
      local output
      local error_output
      output=$(command docker-compose "$@" 2>&1 >/dev/null)
      error_output=$?

      # Check if an error occurred
      if [ "$error_output" -ne 0 ]; then
          local exit_code="$error_output"
          local os_version=$(uname -a)
          local command_run="#{function_name} $*"
          local error_message="Error occurred during '#{function_name} $@' execution: $output"

          casper_track_error "$exit_code" "$os_version" "$command_run" "$output" "$error_message"
      fi
    }
  
    #{new_function_name} "$@"
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

# TODO: to fix, the regex doesn't expect nested brackets.
def remove_casper_command(function_name)
  profile_path = File.expand_path(PROFILE)
  profile_content = File.read(profile_path)

  new_function_name = "#{function_name}"

  casper_block_start = profile_content.index(/(#+\s*)CASPER START/)
  casper_block_end = profile_content.index(/(#+\s*)CASPER END/)

  if casper_block_start && casper_block_end && casper_block_start < casper_block_end
    casper_block_content = profile_content[casper_block_start..casper_block_end]

    # Capture entire function body including brackets {}
    function_regex = /(#{new_function_name}\(\)\s*\{(?:[^{}]*|(?:(casper_#{new_function_name}\(\)\s*\{[^{}]*\}))*)*\})/m


    if casper_block_content.match(function_regex)
      # Remove the function
      casper_block_content.gsub!(function_regex, '')

      # Replace the old CASPER block with the new block in the profile content
      profile_content[casper_block_start..casper_block_end] = casper_block_content

      File.write(profile_path, profile_content)
      puts "Casper command #{new_function_name} removed from test_profile"
    else
      puts "Error: Casper command '#{new_function_name}' not found in test_profile. Cannot remove Casper commands."
    end
  else
    puts "Error: CASPER START and CASPER END comments not found in test_profile. Cannot remove Casper commands."
  end
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
