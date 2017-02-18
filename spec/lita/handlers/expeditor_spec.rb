require "spec_helper"

describe Lita::Handlers::Expeditor, lita_handler: true do

  # Test that routes exist
  it { is_expected.to route_http(:post, "/expeditor/github_event") }
  it { is_expected.to route_command("jenkins build PROJECT GIT_REF") }
  it { is_expected.to route_command("jenkins list") }
  it { is_expected.to route_command("jenkins refresh") }
  it { is_expected.to route_event(:loaded) }

  #
  # Github Event Handler
  #
  describe "github event handler" do
    let(:action) { nil }
    let(:payload) { { "action" => action } }

    let(:response) do
      http.post do |req|
        req.url "/expeditor/github_event"
        req.headers["X-GitHub-Delivery"] = SecureRandom.uuid
        req.headers["X-GitHub-Event"] = event
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.params["payload"] = MultiJson.dump(payload)
      end
    end

    describe "receives a pull_request event" do
      let(:event) { "pull_request" }

      context "with action 'opened'" do
        let(:action) { "opened" }

        it "passes payload to Github helper" do
          expect(::Expeditor::Github).to receive(:handle_pr_opened).with(payload)
          expect(response.status).to eql(200)
        end
      end

      context "with action 'closed'" do
        let(:action) { "closed" }

        it "passes payload to to Github helper" do
          expect(::Expeditor::Github).to receive(:handle_pr_closed).with(payload)
          expect(response.status).to eql(200)
        end
      end

      context "with action 'labeled'" do
        let(:action) { "labeled" }

        it "passes payload to to Github helper" do
          expect(::Expeditor::Github).to receive(:handle_pr_label).with(payload)
          expect(response.status).to eql(200)
        end
      end

      describe "with action 'unlabeled'" do
        let(:action) { "unlabeled" }

        it "passes payload to to Github helper" do
          expect(::Expeditor::Github).to receive(:handle_pr_label).with(payload)
          expect(response.status).to eql(200)
        end
      end
    end

    describe "receives a pull_request_review event" do
      let(:event) { "pull_request_review" }
      let(:action) { "submitted" }

      it "passes payload to to Github helper" do
        expect(::Expeditor::Github).to receive(:handle_pr_review).with(payload)
        expect(response.status).to eql(200)
      end
    end
  end

  #
  # Jenkins Command Handler
  #
  describe "listing Jenkins projects" do
    it "calls out to Jenkins helper" do
      expect(::Expeditor::Jenkins).to receive(:available_projects).and_return(%w{foo bar})
      send_command("jenkins list")
      expect(replies.last).to eql("You can trigger an ad-hoc build for the following projects: foo, bar")
    end
  end

  describe "refreshing Jenkins projects" do
    it "calls out to Jenkins helper and prints available" do
      expect(::Expeditor::Jenkins).to receive(:refresh_projects)
      expect(::Expeditor::Jenkins).to receive(:available_projects).and_return(%w{foo bar})
      send_command("jenkins refresh")
      expect(replies.last).to eql("You can trigger an ad-hoc build for the following projects: foo, bar")
    end

    context "when project refresh fails" do
      it "responds with error message" do
        expect(::Expeditor::Jenkins).to receive(:refresh_projects).and_raise(::Expeditor::Jenkins::HTTPError)
        send_command("jenkins refresh")
        expect(replies.last).to match(/Sorry, received HTTP error/)
      end
    end
  end

  describe "triggering Jenkins build" do
    it "triggers build via Jenkins helper" do
      expect(::Expeditor::Jenkins).to receive(:available_projects).and_return(%w{foo bar})
      expect(::Expeditor::Jenkins).to receive(:trigger_build).with("foo", "GIT_REF", "Test User")
      send_command("jenkins build foo GIT_REF")
      expect(replies.last).to match("Kicked off an ad-hoc Jenkins build for 'foo' at 'GIT_REF'")
    end

    context "when build trigger fails" do
      it "responds with error message" do
        expect(::Expeditor::Jenkins).to receive(:available_projects).and_return(%w{foo bar})
        expect(::Expeditor::Jenkins).to receive(:trigger_build).and_raise(::Expeditor::Jenkins::HTTPError)
        send_command("jenkins build foo GIT_REF")
        expect(replies.last).to match(/Jenkins API Request failed/)
      end
    end

    context "when project does not exist" do
      it "responds with warning message" do
        expect(::Expeditor::Jenkins).to receive(:available_projects).twice.and_return(%w{baz bar})
        send_command("jenkins build foo GIT_REF")
        expect(replies.last).to eql("An ad-hoc trigger for 'foo' could not be found. Please specify one of the following projects: baz, bar")
      end
    end
  end
end
