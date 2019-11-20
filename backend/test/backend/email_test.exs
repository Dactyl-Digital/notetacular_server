defmodule Backend.EmailTest do
  use ExUnit.Case
  alias Backend.Email

  test "creates a formatted verification email" do
    email = Email.format_verification_email(%{email: "test@test.com", email_verification_token: "test_token"})
    %Bamboo.Email{to: to, subject: subject, html_body: html_body} = email
    
    assert to === "test@test.com"
    assert subject === "Notastical - Please verify your email"
    # TODO: use some regex to test html_body
    # assert html_body === "boom"
  end
end