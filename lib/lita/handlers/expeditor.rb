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

module Lita
  module Handlers
    # This lita plugin handles all the communication between the user and
    # the helper classes. Any communication going to the user should be
    # handled by this class.
    class Expeditor < Handler
      include ::Expeditor::Slack::Format

      #
      # Configuration
      #

      # @return [Hash] Hash of 1 or more Jenkins configuration hashes.
      #
      # @example Configuration with mulitple connections
      #   jenkins_endpoints = {
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
          payload = ::Expeditor::Github.extract_payload(request)

          case payload["action"]
          when "opened"
            ::Expeditor::Github.handle_pr_opened(payload)
          when "closed"
            ::Expeditor::Github.handle_pr_closed(payload)
          when "labeled", "unlabeled"
            ::Expeditor::Github.handle_pr_label(payload)
          end
        # https://developer.github.com/v3/activity/events/types/#pullrequestreviewevent
        when "pull_request_review"
          payload = ::Expeditor::Github.extract_payload(request)
          ::Expeditor::Github.handle_pr_review(payload)
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
          "jenkins build PROJECT GIT_REF" => "Trigger an ad-hoc build for PROJECT using GIT_REF",
        }
      ) do |response|
        project = response.args[1]
        git_ref = response.args[2]

        if available_jenkins_projects.include?(project)
          begin
            ::Expeditor::Jenkins.trigger_build(project, git_ref, response.user.name)
            response.success("Kicked off an ad-hoc Jenkins build for '#{project}' at '#{git_ref}'")
          rescue ::Expeditor::Jenkins::HTTPError => e
            response.error("Sorry, received HTTP error kicking off '#{project}' build at '#{git_ref}': #{backquote(e.message)}")
          end
        else
          response.error("An ad-hoc trigger for '#{project}' could not be found. Please specify one of the following projects: #{available_jenkins_projects}")
        end
      end

      # Get a list of all the projects configured with Jenkins ad-hoc triggers
      route(
        /^jenkins\s+list/i,
        command: true,
        help: {
          "jenkins list" => "List the projects available for ad-hoc build",
        }
      ) do |response|
        response.success("You can trigger an ad-hoc build for the following projects: #{available_jenkins_projects}")
      end

      # Refresh the list of jenkins projects
      route(
        /^jenkins\s+refresh/,
        command: true,
        help: {
          "jenkins refresh" => "Refresh the list of ad-hoc triggers available to build",
        }
      ) do |response|
        begin
          ::Expeditor::Jenkins.refresh_projects
          response.success("You can trigger an ad-hoc build for the following projects: #{available_jenkins_projects}")
        rescue ::Expeditor::Jenkins::HTTPError => e
          response.error("Sorry, received HTTP error refreshing the list of projects: #{backquote(e.message)}")
        end
      end

      #
      # Event Endpoints
      #

      # Once every day, refresh the list of ad-hoc triggers
      on :loaded do |_payload|
        every(86400) { ::Expeditor::Jenkins.refresh_projects }
      end

      # Required by Lita - register this plugin with the Lita instance
      Lita.register_handler(self)

      private

      # @return [String] Available projects separated by comma
      def available_jenkins_projects
        ::Expeditor::Jenkins.available_projects.join(", ")
      end
    end
  end
end
