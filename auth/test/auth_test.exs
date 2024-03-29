defmodule AuthTest do
  use ExUnit.Case
  use AuthBuilders
  doctest Auth

  defp hash_password(context) do
    {:ok, Map.put(context, :password_hash, Auth.hash_password("password"))}
  end

  defp setup_user(context) do
    {:ok,
     Map.put(context, :user, %{id: 1, username: "user1", password_hash: context.password_hash})}
  end

  defp setup_session_data_and_hashed_remember_token(context) do
    {:ok, {session_data, hashed_remember_token}} = Auth.create_session_data(1)
    context = Map.put(context, :session_data, session_data)
    {:ok, Map.put(context, :hashed_remember_token, hashed_remember_token)}
  end

  describe "ensuring that password hashing and checking works as intended" do
    setup [:hash_password, :setup_user]

    test "password_hash is not equal to original plain-text password", %{
      password_hash: password_hash
    } do
      assert password_hash !== "password"
    end

    test "check_password/2 returns user info on successful password_hash match", %{user: user} do
      # assert create_n_users(2) == :world
      assert :ok = Auth.check_password(user, "password")
    end

    test "check_password/2 returns error info on failed password_hash match", %{user: user} do
      assert {:error, "Username or password is incorrect."} ===
               Auth.check_password(user, "password2")
    end
  end

  describe "ensuring that session data generation and later retrieval of user from the session works as intended" do
    setup [:setup_session_data_and_hashed_remember_token]

    test "session data to be stored on cookie is generated as expected", %{
      session_data: session_data
    } do
      # NOTE: Reference elixer-pizza's Account context line 186 of impl.ex's login_user function.
      #       Would be great if I implemented that function in this Auth's context...
      assert %{expiry: expiry, remember_token: remember_token, credential_id: credential_id} =
               session_data
    end

    # NOTE: Including an atom in the test string causes this error:
    # == Compilation error in file test/auth_test.exs ==
    #   ** (SystemLimitError) a system limit has been reached
    #       :erlang.list_to_atom('-test ensuring that session data generation and later
    #       retrieval of user from the session works as intended check_authorization/2 - if session is
    #       valid and user\'s remember_token matches the hashed_remember_token then {:ok, %{user_id: user_id}}
    #       is returned/1-fun-0-')
    test "check_authorization/2 - if session is valid and user's remember_token matches the hashed_remember_token then map w/ user_id is returned",
         %{session_data: session_data, hashed_remember_token: hashed_remember_token} do
      credential = %{user_id: 1, hashed_remember_token: hashed_remember_token}

      assert {:ok, %{user_id: 1}} =
               Auth.check_authorization(session_data, fn _credential_id -> credential end)
    end

    test "check_authorization/2 - if current time exceeds session_data's expiry time then message to clear session is returned.",
         %{session_data: session_data, hashed_remember_token: hashed_remember_token} do
      user = %{hashed_remember_token: hashed_remember_token}
      expired_session_data = session_data |> Map.put(:expiry, Timex.now() |> DateTime.to_unix())

      assert {:error, "Invalid session"} =
               Auth.check_authorization(expired_session_data, fn _username -> user end)
    end
  end
end
