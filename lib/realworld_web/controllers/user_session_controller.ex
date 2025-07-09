defmodule RealworldWeb.UserSessionController do
  use RealworldWeb, :controller

  alias Realworld.Accounts
  alias RealworldWeb.UserAuth

  def new(conn, _params) do
    render(conn, :new, error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      # Update user's timezone if provided and different from current
      if time_zone = user_params["time_zone"] do
        if time_zone != user.time_zone do
          Accounts.update_user_time_zone(user, time_zone)
        end
      end
      
      conn
      |> put_flash(:info, "Welcome back!")
      |> UserAuth.log_in_user(user, user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, :new, error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
