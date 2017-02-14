# lita-expeditor

[![Build Status](https://travis-ci.org/chef/lita-Expeditor.png?branch=master)](https://travis-ci.org/chef/lita-expeditor)
[![Coverage Status](https://coveralls.io/repos/chef/lita-Expeditor/badge.png)](https://coveralls.io/r/chef/lita-expeditor)

This is a lita plugin to accelerate development at Chef Software, Inc. for
projects managed through Github.

## Installation

Add lita-expeditor to your Lita instance's Gemfile:

``` ruby
gem "lita-expeditor"
```

## Configuration

### Step One: Setup your `.expeditor.toml`

The `.expeditor.toml` is how Expeditor determines how to handle the various
actions it supports. Place the `.expeditor.toml` in the root of your project.

``` toml
# Scripts or commands to execute when various events trigger (optional)
["Event Triggers"]

  # This command is executed when a PR is merged. Good for bumping versions
  # and updating changelogs. Automatically triggers a git commit and push
  # to master upon successful completion.
  merge = "./ci/version_bump.sh"

  # This script is executed when an artifact is promoted (via Julia) to stable.
  # Good for updating various references to stable versions in your repository
  # or documentation. Automatically triggers a git commit and push to master
  # upon successful completion.
  promotion = "./ci/promotion_cleanup.sh"

# The Slack channel to send notifications to when certain events happen. Can be
# a single channel, or an array of channels.
[Slack]
  channel = "chef-notify"

# These are commands you wish to happen on some regular interval. Timers are
# re-evaluated (and updated if necessary) when this file is updated on master.
[Timers]

  # One example of a timer you may want is that you wish to update the
  # dependencies once every 36 hours. Each timer requires two pieces of
  # information:
  #   1. The frequency (in seconds)
  #   2. The command to run
  [Timers."Update Dependencies"]

    # The frequency to run this command (in seconds)
    frequency = "86400"

    # The command to execute. Automatically opens a new pull request against
    # the repository upon completion.
    command = "./ci/dependency_update.sh"

# On every PR, run various status checks. The sub-sections outlined below are
# the only ones supported, but they are optional.
["Status Checks"]

  # For projects that fall under the chef-rfc Maintenance Policy.
  ["Status Checks".Maintainers]

    # Link to the raw toml file
    toml = "https://raw.githubusercontent.com/chef/chef/master/MAINTAINERS.toml"

    # Which component in the maintainers toml file applies to this project
    component = "chef"

    # The number of maintainer approvals required
    required_approvals = 2

    # If the PR author is a maintainer, does that count as an approval?
    include_submitter = true

    # If a maintainer "requests changes" on PR, do we enforce that a majority
    # of maintainers need to give their approval?
    enforce_majority = true

  # If you use labels in any of your automation, and you wish to enforce checks
  # on various grouping of labels, you can specify them here.
  #
  # Each label sub-category requires two pieces of information:
  #   1) restriction: "exactly-N" or "atleast-N" where N is any number
  #   2) labels: the array of label strings to check against
  ["Status Checks".Labels]

    # If you are using the github-changelog-generator, what are the labels you
    # use to indicate different sections. We want to make sure there is at least
    # one of those labels applied.
    ["Status Checks".Labels.Changelog]
      restriction = "atleast-1"
      labels = [
        "Type: Bug",
        "Type: Enhancement",
        "Meta: Exclude From Changelog"
      ]

    # chef/chef, for example, uses Labels to dictate how to bump the version.
    # We want to make sure that is only one of those labels applied.
    ["Status Checks".Labels."Version Bump"]
      restriction = "exactly-1"
      labels = [
        "Version: Bump Patch",
        "Version: Bump Minor",
        "Version: Bump Major"
      ]

```

### Step Two: Add the Expeditor webhook to your Github repository

## Usage

### Manual Triggers

Trigger ad-hoc builds for pipelines in Manhattan or Wilson.

    @lita jenkins build <PROJECT> <GIT_REF>

### Event Triggers

#### Labels added/removed from Github PR
Triggers status checks for any labels you may have specified in your `.expeditor.toml`.

#### New Github Pull Request Review is added
Triggers status checks against the maintainer details you may have specified in your `.expeditor.toml`.

#### Github PR Closed
Triggers the merge command specified in the your `.expeditor.toml`.

#### Artifact promoted via Julia
Triggers the promotion command specified in the your `.expeditor.toml`.
