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
  # A monkeypatch of Lita's default response object so we can have more
  # fine-grained control over the formatting of the response (i.e. sending
  # messages as attachments or plaintext messages)
  #
  # https://github.com/litaio/lita/blob/master/lib/lita/response.rb
  class Response

    # If we are using the Slack adapter, send a specially formatted Slack message.
    # Otherwise, just send a plain-text message (i.e. when testing)
    #
    # @param strings [String, Array<String>] The strings to send
    # @return [void]
    def success(*strings)
      reply(strings)

      # In a future iteration, we should put some Slack style on this!
      # if Lita.config.robot.adapter == :slack
      #   attachment = Lita::Adapters::Slack::Attachment.new([strings].flatten.join("\n"), color: "good", mrkdwn_in: %w{ text })
      #   adapter.send_attachment(source, attachment)
      # else
      #   reply(*strings)
      # end
    end

    # If we are using the Slack adapter, send a specially formatted Slack message.
    # Otherwise, just send a plain-text message (i.e. when testing)
    #
    # @param strings [String, Array<String>] The strings to send back
    # @return [void]
    def error(*strings)
      reply(strings)

      # In a future iteration, we should put some Slack style on this!
      # if Lita.config.robot.adapter == :slack
      #   attachment = Lita::Adapters::Slack::Attachment.new([strings].flatten.join("\n"), color: "danger", mrkdwn_in: %w{ text })
      #   adapter.send_attachment(source, attachment)
      # else
      #   reply(*strings)
      # end
    end
  end
end
