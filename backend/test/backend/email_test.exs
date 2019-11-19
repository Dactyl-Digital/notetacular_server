defmodule Backend.EmailTest do
  use ExUnit.Case

  test "sends an email verification email" do
    %Bamboo.Email{to: [nil: to], subject: subject, html_body: html_body} =
      Backend.Email.send_email_verification_email("test@test.com")
    
    assert to === "test@test.com"
    assert subject === "Notastical - Please verify your email"
    # TODO: use some regex to test html_body
    # assert html_body === "boom"
  end
end