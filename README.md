# 👻 Casper: The error tracker for devops development scripts


Casper is an automated error tracking and monitoring tool for development scripts.

It tracks errors in development scripts to streamline issue troubleshooting, reducing time and effort spent on environment-related problems by alerting parties early and recording common occurrences and resolutions.

**Spend more time coding, and less time fixing environment issues**

It is designed to be user-friendly, lightweight with no extensive training needed to adopt it.

## How it works

Capser overwrites specified commands on your shell session to wrap a bug tracker arround them.

It'll look for command defined in your `casperconfig.yaml` file to identify which command it should track, then it'll update a `~/.casper_profile` file you can use with your terminal session that contains all the overwrite for the commands you want to track.

#### For example:
If you've specified to track `docker-compose` commands, Casper will monitor this command for errors and handle them by either:
- Sending a notification to a slack #channel
- Updating a local log file
- Sending and http request to a specified endpoint with a payload

You can pick which alert system you want to use.


## Getting Started

To start using Casper, follow these steps:

### 1. Initializse your casper profile

`touch ~/.casper_profile`

### 2. Set your config file

`cp casperconfig.yaml.sample casperconfig.yaml`

#### How to use casperconfig.yaml

```
error_phantom_token: YOUR_ERROR_PHANTOM_TOKEN
plugins:
- name: Docker
  commands:
  - docker
  - docker-compose
- name: Homebrew
  commands:
  - brew
- name: Casper
  commands:
  - casper test
```

The error_phantom_token key is optional. This is solly used to connect Casper with the ErrorPhantom Dashboard.

Commands should be grouped by plugins. This grouping is used to group errors on the ErrorPhantom Dashboard.

You can add multiple commands under a given plugins.

Two different plugin cannot have the same command name.

###  3. Load your casper profile in your shell session

Type the following command to populate ` ~/.casper_profile` with your configuration from `casperconfig.yaml`:

```
casper set
```

Then load it into your shell session:

```
source ~/.casper_profile
```

That's it! Now Casper is setup.


### 4. Verify that casper is working

When tracker is set for a command you'll see:

`👻 Casper is watching and tracking issues for: [script-name]...` 

before each command that casper is monitoring.

### Slack – How to configure casper with slack

`Work in progress`

When casper notify slack you'll see:

```
👻 sharing this issue on #casper-dev-prod
[...the dev-prod team was notified of this issue with launch-remote.sh]
```

## To uninstall the profile from your session

Run the following command to clear your `~/.casper_profile`
```
casper unset
```

Then load the updated file into your session
```
source ~/.casper_profile
```
### Use your shell without Casper

You can just restart or close the window or session to remove casper. 

When you open a new session it won't start with your casper profile loaded.

## Benefits of Using:

#### 1. Casper Tracker

**Less Struggle with Environment Issues:** Developers spend less time resolving issues they have limited context on on, and get support more efficiently.

**Faster Issue Resolution:** Casper enables early detection of script-related errors, leading to faster issue resolution and smoother development cycles.

**Streamlined Support:** Casper's integration with Slack allows the DevProd team to provide timely support and assistance.

**Efficient Knowledge Sharing:** Casper serves as a valuable knowledge base, centralizing development env error information and common fixes, reducing redundant support requests and duplicated slack comment threads.

#### 2. Casper Tracker + Monitoring Dashboard

`TBD: The monitoring dashoard is still in development`

**Data-Driven Decision Making:** By tracking and measuring the most common script issues, Casper can provides insights into their impact on the team's productivity, helping prioritize fixes for recurring issues.

**Increased Developer Productivity:** Since Casper can minimize the time spent on environment problems, developers can now focus more on their core tasks, leading to enhanced productivity.

**Collaboration:** Make it easier for team to collaborate on script related issues.

**Improve Documentation**: By tracking the occurence of error for various machine it gives an engineering team the ability to add more contex to a documentation on how to resolve a specific issue.

**Easily track and find resolution**: Quickly identify issues that were already resolved and by whom.

## Security

Casper can be configure to redact sensitive information from error messages. As the tool is designed for local environments, it does not handle production data or expose confidential information.

`TBD`

## Fine-tuning alerting rules

By design Casper use intelligent error filtering, which  minimizes unnecessary notifications and ensures the team is only alerted for critical issues they want to track.


Some additional rules will be added to reduce false positives and control the frequency of alerts through the monitoring dashboard

`TBD`

## TODO
- Update casper_runner.rb to load and use the configuration.rb file constants
- Add slack integration
- Add http integration: ability to send a request to an HTTP endpoint (would be helpful for a dashboard with a db to collect occurences and have additional insights)
- Add ability to specific a callback for specific errors (e.g: a link to a page with common resolution for the plugin)
- Add Alert-rules to reduce false positives and control the frequency of alerts.(e.g: After x occurence do not post on slack – but still count the error)
- Add local env dashboard to track local occurences and resolutions.

## Author

Casper was created by Richardson Dackam. 

## Contributors

TBD
