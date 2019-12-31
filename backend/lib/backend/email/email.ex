defmodule Backend.Email do
  use Bamboo.Phoenix, view: Backend.EmailView
  import Bamboo.Email
  alias Dbstore.{User, Credential}

  # TODO: Use Official Notastical email.
  @sender_email "mailgun@notastical.com"

  @doc """
    This function is meant to be used within the sign up controller:

    Success case:
    {:delivered_email, _email} = Backend.Email.deliver_email_verification_email(user_email)

    Failure case:
    {:err, message} = Backend.Email.deliver_email_verification_email(user_email)
  """
  def deliver_email_verification_email(email) do
    with {:ok, {token, hashed_token}} <- Auth.create_hashed_email_verification_token(),
         %Credential{id: id} <- Accounts.retrieve_users_credentials_by_email(email),
         {:ok, _} <-
           Accounts.update_user_token(:hashed_email_verification_token, id, hashed_token) do
      create_email_verification_email(email, token)
      |> Backend.Mailer.deliver_now()
    else
      nil ->
        {:error, "UNAUTHORIZED_REQUEST"}

      {:error, _} ->
        {:error, "Failed to save hashed_email_verification_token to the database."}
    end
  end

  def create_email_verification_email(email, token) do
    format_verification_email(%{email: email, email_verification_token: token})
  end

  def format_verification_email(%{
        email: email,
        email_verification_token: email_verification_token
      }) do
    base_email()
    |> to(email)
    |> from(@sender_email)
    |> subject("Notastical - Please verify your email")
    |> assign(:email, email)
    |> assign(:email_verification_token, email_verification_token)
    |> render("email_verification.html")
  end

  def base_email do
    new_email()
    |> put_html_layout({Backend.EmailView, "email.html"})
  end
end
