class FeedbackController < ApplicationController
  def send_mail
    return if params[:body].length == 0
    raise 'up to 2048 chars' if params[:body].length > 2048

    FeedbackMailer.send_feedback(params[:body]).deliver
    render
  end
end
