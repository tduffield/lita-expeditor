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

require "expeditor/jenkins/http"

module Expeditor
  # Lita-facing API to communicate with Chef's internal Jenkins instances
  class Jenkins
    extend Forwardable

    def_delegators :instance, :available_projects, :refresh_projects, :trigger_build

    def initialize
      configure_endpoints
      refresh_projects
    end

    # Get a list of the projects we have access to
    #
    # @return [Array#String] List of projects that can be build
    def available_projects
      @projects.keys.sort.uniq.map(&:to_s)
    end

    # Query the Jenkins API to refresh the list of projects we can build
    #
    # Iterate through each of the endpoints and query the API to get a list
    # of all the jobs available on that Jenkins instance. Parse out all the
    # jobs that match the trigger-ad_hoc regex and return them.
    #
    # @return [void]
    def refresh_projects
      @projects = {}
      @endpoints.each do |name, jenkins|
        MultiJson.load(jenkins.get("/api/json"))["jobs"].each do |job|
          @projects[$1] = jenkins if job["name"] =~ /(.*)-trigger-ad_hoc/
        end
      end
    end

    # Trigger a Jenkins build for a specific project
    #
    # @param project [String] The project to build
    # @param git_ref [String] The git reference (sha, branch, or tag) to build from
    # @param initiated_by [String] The user that triggered the build
    # @return [void]
    def trigger_build(project, git_ref, initiated_by = "Chef Expeditor")
      jenkins = @projects[project]
      pipeline = "#{project}-trigger-ad_hoc"

      jenkins.post("/job/#{pipeline}/buildWithParamters",
                   "GIT_REF" => git_ref,
                   "EXPIRE_CACHE" => false,
                   "INITIATED_BY" => initiated_by)
    end

    private

    # Iterate through each of the Jenkins endpoints configured and create a
    # Jenkins::HTTP instance for each one.
    #
    # @return [Hash] Hash of endpoints and their associated Jenkins::HTTP instance
    # @return [void]
    def configure_endpoints
      @endpoints = {}
      Lita.config.handlers.expeditor.jenkins_endpoints.each do |name, opts|
        @endpoints[name] = HTTP.new(
          base_uri: opts[:uri],
          username: opts[:username],
          api_token: opts[:api_token])
      end
    end
  end
end
