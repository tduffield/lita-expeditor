#
# Copyright:: Copyright 2017 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "expeditor"

module Lita
  module Handlers
    # This lita plugin handles all the communication between the user and
    # the helper classes. Any communication going to the user should be
    # handled by this class. Any logging that needs to happen should be
    # handled by the helper classes via the `robot` instance that's passed
    # to each helper class instance.
    #
    # Lita::Robot :: https://github.com/litaio/lita/blob/master/lib/lita/robot.rb
    #
    class Expeditor < Handler

      # @return [::Expeditor::Github] Interface to Github calls
      attr_reader :github

      # @return [::Expeditor::Jenkins] Interface to Jenkins calls
      attr_reader :jenkins

      # @return [::Expeditor::Slack] Interface with Slack
      attr_reader :slack

      def initialize(robot)
        super(robot)

        @github = ::Expeditor::Github.new(robot)
        @jenkins = ::Expeditor::Jenkins.new(robot)
        @slack = ::Expeditor::Slack.new(robot)
      end

      #
      # Configuration
      #

      # @return [Hash] Hash of 1 or more Jenkins configuration hashes.
      #
      # @example Configuration with mulitple connections
      #   endpoints = {
      #     volleyball: {
      #        uri: http://volleyball.ci.chef.co",
      #        username: chef-survivor",
      #        api_token: XXXXXXXXXXXXXXXXXX"
      #     },
      #     brooklyn: {
      #        uri: http://brooklyn.ci.chef.co",
      #        username: chef-redapple",
      #        api_token: XXXXXXXXXXXXXXXXXX"
      #     }
      #   }
      config :jenkins_endpoints, required: true

      #
      # HTTP Endpoints
      #

      # Handle Github Webhook events
      http.post "/expeditor/github_event" do |request, response|
        case request.env["HTTP_X_GITHUB_EVENT"]
        # https://developer.github.com/v3/activity/events/types/#pullrequestevent
        when "pull_request"
          payload = github.extract_payload(request)

          case payload["action"]
          when "opened"
            github.handle_pr_opened(payload)
          when "closed"
            github.handle_pr_closed(payload)
          when "labeled", "unlabeled"
            github.handle_pr_label(payload)
          end
        # https://developer.github.com/v3/activity/events/types/#pullrequestreviewevent
        when "pull_request_review"
          github.handle_pr_review(github.extract_payload(request))
        end
      end

      #
      # Chat Endpoints
      #

      # Trigger a Jenkins ad-hoc build
      REGEX = /[\w\-\.\+\_]+/
      route(
        /^jenkins\s+build\s+#{REGEX.source}\s+#{REGEX.source}/i,
        command: true,
        help: {
          "jenkins build PROJECT GIT_REF" => "Trigger an ad-hoc build for PROJECT at GIT_REF"
        }
      ) do |response|
        project = response.args[1]
        git_ref = response.args[2]

        if jenkins.available_projects.include?(project)
          begin
            jenkins.trigger_build(project, git_ref)
            slack.respond("Kicked off a Jenkins build for '#{project}' at '#{git_ref}'")
          rescue ::Expeditor::Jenkins::HTTPError => e
            slack.respond_error(e.message)
          end
        else
          slack.respond_warn("An ad-hoc trigger for '#{project}' could not be found. Please specify one of the following projects: #{jenkins.available_projects.join(", ")}")
        end
      end

      # Get a list of all the projects configured with Jenkins ad-hoc triggers
      route(
        /^jenkins\s+list/i,
        command: true,
        help: {
          "jenkins list" => "List the projects available for ad-hoc build"
        }
      ) do |response|
        begin
          slack.respond("You can trigger an ad-hoc build for the following projects: #{jenkins.available_projects.join(", ")}")
        rescue ::Expeditor::Jenkins::HTTPError => e
          slack.respond_error(e.message)
        end
      end

      # Refresh the list of jenkins projects
      route(
        /^jenkins\s+refresh/,
        command: true,
        help: {
          "jenkins refresh" => "Refresh the list of ad-hoc triggers available to build"
        }
      ) do |response|
        begin
          jenkins.refresh_projects
          slack.respond("You can trigger an ad-hoc build for the following projects: #{jenkins.available_projects.join(", ")}")
        rescue ::Expeditor::Jenkins::HTTPError => e
          slack.respond_error(e.message)
        end
      end

      #
      # Event Endpoints
      #

      # Once every day, refresh the list of ad-hoc triggers
      on :loaded do |_payload|
        every(86400) { jenkins.refresh_projects }
      end

      # Required by Lita - register this plugin with the Lita instance
      Lita.register_handler(self)

    end
  end
end
