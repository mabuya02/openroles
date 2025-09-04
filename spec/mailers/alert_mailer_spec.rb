require "rails_helper"

RSpec.describe AlertMailer, type: :mailer do
  describe "job_alert_notification" do
    let(:mail) { AlertMailer.job_alert_notification }

    it "renders the headers" do
      expect(mail.subject).to eq("Job alert notification")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
