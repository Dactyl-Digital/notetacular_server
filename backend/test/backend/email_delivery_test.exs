defmodule Backend.EmailDeliveryTest do
  use ExUnit.Case
  use Bamboo.Test
  alias Backend.Email

  test "sends an email verification email" do
    {_, {:delivered_email, email}} =
      Email.create_email_verification_email("test@test.com", "test_token") |> Backend.Mailer.deliver_now(response: true)
    assert_delivered_email email
  end
end