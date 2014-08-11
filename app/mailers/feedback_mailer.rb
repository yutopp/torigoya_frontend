class FeedbackMailer < ActionMailer::Base
  default from: "feedback@sc.yutopp.net"

  def send_feedback(body)
    @body = body
    mail(:to => 'yutopp+sc.feedback@gmail.com',
         :subject => '[feedback] ProcGarden'
         )
  end
end
