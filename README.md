# lita-expeditor

[![Build Status](https://travis-ci.org/chef/lita-Expeditor.png?branch=master)](https://travis-ci.org/chef/lita-expeditor)

This is a Lita plugin to accelerate development at Chef Software, Inc. for
projects managed through Github.

## Installation

Add lita-expeditor to your Lita instance's Gemfile:

``` ruby
gem "lita-expeditor"
```

## Configuration

The following configuration parameters are required:

    config.handlers.expeditor.jenkins_endpoints

## Usage

### Configuration

#### Jenkins Endpoints

Expeditor takes in an array of multiple Jenkins endpoints.

    config.handlers.expeditor.jenkins_endpoints = {
      volleyball: {
        uri: "http://volleyball.ci.chef.co",
        username: "chef-survivor",
        api_token: "XXXXXXXXXXXXXXXXXX"
      },
      brooklyn: {
        uri: "http://brooklyn.ci.chef.co",
        username: "chef-redapple",
        api_token: "XXXXXXXXXXXXXXXXXX"
      }
    }

### Chat Routes

Get a list of all the Jenkins projects from Manhattan or Wilson that you can build.

    @lita jenkins list

Trigger an ad-hoc build for a pipeline in Manhattan or Wilson.

    @lita jenkins build <PROJECT> <GIT_REF>

In the case of a server restart, or if a pipeline has been added or removed, run this command to refresh the available projects.

    @lita jenkins refresh
