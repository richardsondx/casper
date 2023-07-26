# test_casper.rb

# Method to execute shell commands and print their output
def execute(command)
  puts "Executing: #{command}"
  system(command)
end

# Function name and plugin name to test
function_name = 'docker-compose'
plugin_name = 'Docker'

# Add the Casper command to track errors for the specified function and plugin
execute("ruby casper_runner.rb set #{function_name} #{plugin_name}")

# Now, run a command that triggers an error
execute("echo 'This is a test error' && exit 1")

# Wait for a while to observe the error logging in the log.txt file (if applicable)
sleep 5

# Remove the Casper command from the specified function and plugin
execute("ruby casper_runner.rb unset #{function_name} #{plugin_name}")