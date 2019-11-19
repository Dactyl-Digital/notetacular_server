defmodule Backend.Email do
  use Bamboo.Phoenix, view: Backend.EmailView
  import Bamboo.Email

  @sender_email "jamesgood@dactyl.digital"
  
  def send_email_verification_email(email) do
    {:ok, {token, hashed_token}} = Auth.create_hashed_email_verification_token()
    # TODO:
    # retrieve user's credentials via email
    # And update the hashed_token and expiry to user's credentials to the DB
    create_verification_email(%{email: email, email_verification_token: token})
    |> Backend.Mailer.deliver_now()
  end
  
  defp create_verification_email(%{
      email: email,
      email_verification_token: email_verification_token,
  }) do
    base_email
    |> to(email)
    |> from(@sender_email)
    |> subject("Notastical - Please verify your email")
    |> assign(:email, email)
    |> assign(:email_verification_token, email_verification_token)
    |> render("email_verification.html")
    |> IO.inspect
  end

  def base_email() do
    new_email
    |> put_html_layout({Backend.EmailView, "email.html"})
  end
end