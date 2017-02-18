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

describe Lita::Response do
  subject { described_class.new(message, /dummy regexp/) }

  let(:message) { instance_double("Lita::Message").as_null_object }
  let(:string) { "test string" }

  describe "#success" do
    it "sends message normally" do
      expect(message).to receive(:reply).with([string])
      subject.success(string)
    end
  end

  describe "#error" do
    it "sends message normally" do
      expect(message).to receive(:reply).with([string])
      subject.error(string)
    end
  end
end
