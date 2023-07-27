# Change this to your desired shell profile. We recommend to use the default casper_profile
PROFILE = '~/.casper_profile'

# If ALERT_TYPE is set to :log, all the log will go there
LOG_FILE= '/tmp/casper_log.txt'

# Change this to :log, :http_request, or :slack based on the desired alert method
ALERT_TYPE = :log

# Change this to false to disable logging of backtrace
LOG_BACKTRACE = true 