defmodule BackendWeb.AuthControllerTest do
  use BackendWeb.ConnCase
  alias Dbstore.{Repo, User}
  alias Backend.Email
  
  def extract_email_verification_link_from_html(html_body) do
    link_with_html_encoding = ~r/\/api.*\.com/ |> Regex.run(html_body) |> Enum.at(0)
    link = Regex.replace(~r/amp;/, link_with_html_encoding, "")
    Regex.replace(~r/%40/, link, "@")
  end
  
  setup do
    on_exit(fn ->
      Repo.delete_all("credentials")
      Repo.delete_all("memberships")
      Repo.delete_all("users")
    end)  
  end
  
  setup_all do
    # handles clean up after all tests have run
    on_exit(fn ->
      Repo.delete_all("credentials")
      Repo.delete_all("memberships")
      Repo.delete_all("users")
    end)

    :ok
  end
  
  test "POST /api/signup signs up a user w/ unique username and email in an account_active: false state", %{conn: conn} do
    conn = post(conn, "/api/signup", %{
      email: "test@test.com",
      username: "testuser",
      password: "testpassword"
    })

    assert %{"message" => "Please verify your email"} === json_response(conn, 201)
  end
  
  test "GET /api/verify-email completes the signup process and sets account_active: true", %{conn: conn} do
    conn = post(conn, "/api/signup", %{
      email: "test@test.com",
      username: "testuser",
      password: "testpassword"
    })
    {_, {:delivered_email, %{html_body: html_body}}} =
      Email.deliver_email_verification_email("test@test.com")
    email_verification_endpoint = extract_email_verification_link_from_html(html_body)
    # unit test the helper function
    # assert "/api/verify-email?email_verification_token=test_token&email=test@test.com" === email_verification_endpoint
    conn = get(conn, email_verification_endpoint)
    assert %{"message" => "You've successfully verified your email!"} = json_response(conn, 200)
  end
end