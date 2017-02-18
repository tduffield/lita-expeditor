require "lita-expeditor"
require "lita/rspec"

# For UUID generation
require "securerandom"

# A compatibility mode is provided for older plugins upgrading from Lita 3. Since this plugin
# was generated with Lita 4, the compatibility mode should be left disabled.
Lita.version_3_compatibility_mode = false

module Expeditor
  module RSpec
    class << self

      # Some common test setup for use inside the Expeditor test specs.
      def included(base)
        base.class_eval do
          let(:registry) { Lita::Registry.new }
          let(:robot) { Lita::Robot.new(registry) }
          let(:handler) { Lita::Handlers::Expeditor.new(robot) }

          let(:jenkins_endpoints) do
            {
              volleyball: {
                 uri: "http://volleyball.ci.chef.co",
                 username: "chef-survivor",
                 api_token: "XXXXXXXXXXXXXXXXXX",
              },
              brooklyn: {
                 uri: "http://brooklyn.ci.chef.co",
                 username: "chef-redapple",
                 api_token: "XXXXXXXXXXXXXXXXXX",
              },
            }
          end

          before do
            stub_const("Lita::REDIS_NAMESPACE", "lita.test")
            keys = Lita.redis.keys("*")
            Lita.redis.del(keys) unless keys.empty?
            Lita.config.handlers.expeditor.jenkins_endpoints = jenkins_endpoints
            registry.register_handler(Lita::Handlers::Expeditor)
          end
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include ::Expeditor::RSpec, lita_helper: true
end
