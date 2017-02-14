require "spec_helper"

describe Lita::Handlers::Expeditor, lita_handler: true do

  # Test that routes exist
  it { is_expected.to route_http(:post, "/expeditor/github_event") }
  it { is_expected.to route_command("jenkins build PROJECT GIT_REF") }
  it { is_expected.to route_command("jenkins list") }
  it { is_expected.to route_command("jenkins refresh") }
  it { is_expected.to route_event(:loaded) }

  let(:github) { ::Expeditor::Github.new(robot) }
  let(:jenkins) { ::Expeditor::Jenkins.new(robot) }
  let(:slack) { ::Expeditor::Slack.new(robot) }

  before do
    allow(::Expeditor::Github).to receive(:new).and_return(github)
    allow(::Expeditor::Jenkins).to receive(:new).and_return(jenkins)
    allow(::Expeditor::Slack).to receive(:new).and_return(slack)
  end

  describe "handler initialization" do
    it "creates helper instances" do
      expect(subject.github).to eql(github)
      expect(subject.jenkins).to eql(jenkins)
      expect(subject.slack).to eql(slack)
    end
  end

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
          expect(subject.github).to receive(:handle_pr_opened).with(payload)
          expect(response.status).to eql(200)
        end
      end

      context "with action 'closed'" do
        let(:action) { "closed" }

        it "passes payload to to Github helper" do
          expect(subject.github).to receive(:handle_pr_closed).with(payload)
          expect(response.status).to eql(200)
        end
      end

      context "with action 'labeled'" do
        let(:action) { "labeled" }

        it "passes payload to to Github helper" do
          expect(subject.github).to receive(:handle_pr_label).with(payload)
          expect(response.status).to eql(200)
        end
      end

      describe "with action 'unlabeled'" do
        let(:action) { "unlabeled" }

        it "passes payload to to Github helper" do
          expect(subject.github).to receive(:handle_pr_label).with(payload)
          expect(response.status).to eql(200)
        end
      end
    end

    describe "receives a pull_request_review event" do
      let(:event) { "pull_request_review" }
      let(:action) { "submitted" }

      it "passes payload to to Github helper" do
        expect(subject.github).to receive(:handle_pr_review).with(payload)
        expect(response.status).to eql(200)
      end
    end
  end

  #
  # Jenkins Command Handler
  #
  describe "listing Jenkins projects" do
    it "calls out to Jenkins helper" do
      expect(subject.jenkins).to receive(:available_projects).and_return(%w{foo bar})
      expect(subject.slack).to receive(:respond).with("You can trigger an ad-hoc build for the following projects: foo, bar")
      send_command("jenkins list")
    end

    context "when project fetch fails" do
      it "responds with error message" do
        expect(subject.jenkins).to receive(:available_projects).and_raise(::Expeditor::Jenkins::HTTPError)
        expect(subject.slack).to receive(:respond_error).with(/Jenkins API Request failed/)
        send_command("jenkins list")
      end
    end
  end

  describe "refreshing Jenkins projects" do
    it "calls out to Jenkins helper and prints available" do
      expect(subject.jenkins).to receive(:refresh_projects)
      expect(subject.jenkins).to receive(:available_projects).and_return(%w{foo bar})
      expect(subject.slack).to receive(:respond).with("You can trigger an ad-hoc build for the following projects: foo, bar")
      send_command("jenkins refresh")
    end

    context "when project refresh fails" do
      it "responds with error message" do
        expect(subject.jenkins).to receive(:refresh_projects).and_raise(::Expeditor::Jenkins::HTTPError)
        expect(subject.slack).to receive(:respond_error).with(/Jenkins API Request failed/)
        send_command("jenkins refresh")
      end
    end
  end

  describe "triggering Jenkins build" do
    it "triggers build via Jenkins helper" do
      expect(subject.jenkins).to receive(:available_projects).and_return(%w{foo bar})
      expect(subject.jenkins).to receive(:trigger_build).with("foo", "GIT_REF")
      expect(subject.slack).to receive(:respond).with("Kicked off a Jenkins build for 'foo' at 'GIT_REF'")
      send_command("jenkins build foo GIT_REF")
    end

    context "when build trigger fails" do
      it "responds with error message" do
        expect(subject.jenkins).to receive(:available_projects).and_return(%w{foo bar})
        expect(subject.jenkins).to receive(:trigger_build).and_raise(::Expeditor::Jenkins::HTTPError)
        expect(subject.slack).to receive(:respond_error).with(/Jenkins API Request failed/)
        send_command("jenkins build foo GIT_REF")
      end
    end

    context "when project does not exist" do
      it "responds with warning message" do
        expect(subject.jenkins).to receive(:available_projects).twice.and_return(%w{baz bar})
        expect(subject.slack).to receive(:respond_warn).with("An ad-hoc trigger for 'foo' could not be found. Please specify one of the following projects: baz, bar")
        send_command("jenkins build foo GIT_REF")
      end
    end
  end
end
