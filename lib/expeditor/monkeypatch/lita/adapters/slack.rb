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
  module Adapters
    # This is a monkey-patch of the Lita Slack Adapter.
    #
    # https://github.com/litaio/lita-slack/blob/master/lib/lita/adapters/slack.rb
    class Slack < Adapter

      # We want to be able to properly send data to the correct source, but the
      # Slack adapters logic for this is private. So, rather than duplication
      # this logic we're simply injecting a helper method to be called from our
      # monkey-patch of Lita::Response
      #
      # This is still a work in progress and shouldn't be used yet
      #
      def send_attachment(target, *attachments)
        chat_service.send_attachments(channel_for(target), [attachments].flatten)
      end
      alias_method :send_attachments, :send_attachment
    end
  end
end
