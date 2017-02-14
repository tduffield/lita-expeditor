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

module Expeditor
  class Jenkins

    class HTTPError < StandardError

      attr_reader :base_uri
      attr_reader :request_method
      attr_reader :request_path
      attr_reader :username
      attr_reader :cause

      def initialize(base_uri: nil, request_method: nil, request_path: nil, username: nil, cause: nil)
        @base_uri = base_uri
        @request_method = request_method
        @request_path = request_path
        @username = username
        @cause = cause

        super(generate_error_string)
      end

      private

      def generate_error_string
        error_string = <<-ERROR_MESSAGE
Jenkins API Request failed with #{cause.class}

Request Data:
- Base URI: #{base_uri}
- Request Method: #{request_method}
- Request Path: #{request_path}
- Username: #{username}

ERROR_MESSAGE
        if http_exception?
          error_string << <<-HTTP_ERROR_INFO
Exception:\n- #{cause}
- Response Code: #{cause.response.code}
- Response Body:
#{cause.response.body}
HTTP_ERROR_INFO
        else
          # probably a socket/network issue
          error_string << "Exception:\n- #{cause}\n"
        end

        error_string
      end

      def http_exception?
        cause.respond_to?(:response)
      end

    end
  end
end
