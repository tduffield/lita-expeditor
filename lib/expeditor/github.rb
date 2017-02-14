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

require "expeditor/github/client"

module Expeditor
  class Github

    def initialize(robot)
    end

    def handle_pr_opened(payload)
    end

    def handle_pr_closed(payload)
    end

    def handle_pr_label(payload)
    end

    def handle_pr_review(payload)
    end

    # The location of the payload for a Github request can depend on the
    # Content Type. Look at the media_type of the request and extract
    # the payload accordingly.
    def extract_payload(request)
      case (media_type = request.media_type)
      when "application/x-www-form-urlencoded"
        MultiJson.load(request["payload"])
      when "application/json"
        MultiJson.load(request.body)
      else
        raise "GitHub web hooks: Invalid HTTP Content-Type header: #{media_type}"
      end
    end

  end
end
