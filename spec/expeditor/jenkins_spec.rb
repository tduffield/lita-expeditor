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

require "spec_helper"

describe Expeditor::Jenkins, lita_helper: true do

  let(:volleyball_http) { double("Volleyball HTTP", get: File.read(File.expand_path("../../fixtures/jenkins/volleyball.json", __FILE__))) }
  let(:brooklyn_http) { double("Brooklyn HTTP", get: File.read(File.expand_path("../../fixtures/jenkins/brooklyn.json", __FILE__))) }

  before do
    allow(Expeditor::Jenkins::HTTP).to receive(:new).with(
      base_uri: jenkins_endpoints[:volleyball][:uri],
      username: jenkins_endpoints[:volleyball][:username],
      api_token: jenkins_endpoints[:volleyball][:api_token]
    ).and_return(volleyball_http)
    allow(Expeditor::Jenkins::HTTP).to receive(:new).with(
      base_uri: jenkins_endpoints[:brooklyn][:uri],
      username: jenkins_endpoints[:brooklyn][:username],
      api_token: jenkins_endpoints[:brooklyn][:api_token]
    ).and_return(brooklyn_http)
  end

  describe "#available_projects" do
    it "returns a list of projects" do
      expect(subject.available_projects).to eql(%w{
        angry-omnibus-toolchain
        angrychef
        automate
        chef
        chef-11
        chef-analytics
        chef-backend
        chef-compliance
        chef-manage
        chef-marketplace
        chef-server-12
        chefdk
        delivery
        harmony
        inspec
        omnibus-toolchain
        opscode-push-jobs-server
        opscode-reporting
        push-jobs-client
        supermarket
      })
    end
  end

  describe "#refresh_projects" do
    it "re-calls the API to get an updated list of projects" do
      expect(volleyball_http).to receive(:get)
      expect(brooklyn_http).to receive(:get)
      subject.refresh_projects
    end

    context "when there is an HTTP error" do
      before do
        allow(volleyball_http).to receive(:get).and_raise(Expeditor::Jenkins::HTTPError)
      end

      it "passes error up the stack" do
        expect { subject.refresh_projects }.to raise_error(Expeditor::Jenkins::HTTPError)
      end
    end
  end

  describe "#trigger_build" do
    it "calls out to the appropriate jenkins instance to trigger ad-hoc build" do
      expect(brooklyn_http).to receive(:post).with(
        "/job/chef-trigger-ad_hoc/buildWithParamters",
        "GIT_REF" => "MY_SHA",
        "EXPIRE_CACHE" => false,
        "INITIATED_BY" => "Chef Expeditor"
      )
      subject.trigger_build("chef", "MY_SHA")
    end

    context "when there is an HTTP error" do
      before do
        allow(brooklyn_http).to receive(:post).and_raise(Expeditor::Jenkins::HTTPError)
      end

      it "passes error up the stack" do
        expect { subject.trigger_build("chef", "MY_SHA") }.to raise_error(Expeditor::Jenkins::HTTPError)
      end
    end
  end
end
