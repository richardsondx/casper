# This shell script, casper.sh, is a utility for adding or removing the 'error_tracker' 
# from a specified 'function_name' in the 'casperconfig.yaml' file.

# Usage:
#   - To add 'error_tracker' to 'function_name', run:
#       ./casper.sh set
#   - To remove 'error_tracker' from 'function_name', run:
#       ./casper.sh unset

# Before using this script, ensure you have a backup of the 'casperconfig.yaml' file, 
# as it will directly modify the file.
# Replace 'your_function_name' in the script with the actual function name you want to modify.

# The 'casperconfig.yaml' file should contain:
#   - 'error_phantom_token': ErrorPhantom token for error reporting (replace with your token).
#   - 'plugins': A list of plugins and their associated commands that Casper should track 
#     for error monitoring. Each plugin has a 'name' and an array of 'commands'.

# Note: This script assumes that the 'function_name' does not contain special characters 
# like '!', '^', etc., which may require additional handling in the script.
# Make sure to adjust the paths if your 'casperconfig.yaml' file is in a different location.

# casper.sh

function_name="your_function_name"

if [ "$1" = "set" ]; then
  ruby casper_runner.rb set "$function_name"
elif [ "$1" = "unset" ]; then
  ruby casper_runner.rb unset "$function_name"
else
  echo "Usage: $0 set or $0 unset"
fi