defmodule BackendWeb.AuthControllerTest do
  use BackendWeb.ConnCase
  alias Dbstore.{Repo, User}
  alias Backend.Email

  def extract_email_verification_link_from_html(html_body) do
    link_with_html_encoding = ~r/\/api.*\.com/ |> Regex.run(html_body) |> Enum.at(0)
    link = Regex.replace(~r/amp;/, link_with_html_encoding, "")
    Regex.replace(~r/%40/, link, "@")
  end

  # setup do
  #   on_exit(fn ->
  #     Repo.delete_all("credentials")
  #     Repo.delete_all("memberships")
  #     Repo.delete_all("users")
  #   end)
  # end
  def setup_user(context) do
    {:ok, user} =
      %User{}
      |> User.changeset(%{
        username: "testuser",
        account_active: true,
        credentials: %{
          email: "test@test.com",
          password: "testpassword"
        },
        memberships: %{
          subscribed_until: Timex.now() |> Timex.shift(days: 30)
        }
      })
      |> Repo.insert()

    {:ok, user} =
      user
      |> User.activate_account_changeset(%{
        account_active: true,
        credentials: %{
          id: user.credentials.id,
          email_verification_token_expiry: nil,
          hashed_email_verification_token: nil
        }
      })
      |> Repo.update()

    context = Map.put(context, :user, user)
    {:ok, context}
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

  test "POST /api/signup signs up a user w/ unique username and email in an account_active: false state",
       %{conn: conn} do
    conn =
      post(conn, "/api/signup", %{
        email: "test2@test.com",
        username: "testuser2",
        password: "testpassword2"
      })

    assert %{"message" => "Please verify your email"} === json_response(conn, 201)
  end

  test "GET /api/verify-email completes the signup process and sets account_active: true", %{
    conn: conn
  } do
    email = "test3@test.com"

    conn =
      post(conn, "/api/signup", %{
        email: email,
        username: "testuser3",
        password: "testpassword3"
      })

    %{html_body: html_body} = Email.deliver_email_verification_email(email)

    email_verification_endpoint = extract_email_verification_link_from_html(html_body)
    # unit test the helper function
    # assert "/api/verify-email?email_verification_token=test_token&email=test@test.com" === email_verification_endpoint
    conn = get(conn, email_verification_endpoint)
    assert %{"message" => "You've successfully verified your email!"} = json_response(conn, 200)
  end

  # TODO: Need to write a test for a user attempting to login with a username
  #       that hasn't been created as a user yet. <- Ran into an error for this edge case.
  describe "login and logout functions" do
    setup [:setup_user]

    test "POST /api/login logs in a user with account_active: true", %{conn: conn, user: user} do
      conn = post(conn, "/api/login", %{username: "testuser", password: "testpassword"})

      # assert %{"message" => "Please verify your email"} === json_response(conn, 201)
      assert %{"message" => "You've successfully logged in."} = json_response(conn, 200)
    end
  end
end
