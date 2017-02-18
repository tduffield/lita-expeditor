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

require "lita"

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

require "expeditor/monkeypatch/lita/response"
require "expeditor/monkeypatch/lita/adapters/slack"

require "expeditor/version"
require "expeditor/jenkins"
require "expeditor/github"
require "expeditor/slack"

require "lita/handlers/expeditor"

Lita::Handlers::Expeditor.template_root File.expand_path(
  File.join("..", "..", "templates"),
 __FILE__
)
