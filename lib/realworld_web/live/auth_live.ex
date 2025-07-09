defmodule RealworldWeb.AuthLive do
  @moduledoc """
  LiveView helpers for authentication and authorization.

  Usage in LiveView modules:

      use RealworldWeb, :live_view
      on_mount RealworldWeb.AuthLive

  Or for specific hooks:

      on_mount {RealworldWeb.AuthLive, :require_authenticated_user}
      on_mount {RealworldWeb.AuthLive, :require_admin}
  """
  import Phoenix.LiveView
  import Phoenix.Component

  alias Realworld.Accounts
  alias Realworld.Policies

  # Default mount behavior - just assigns current user if available
  def on_mount(:default, _params, session, socket) do
    {:cont, assign_current_user(socket, session)}
  end

  def on_mount(:require_authenticated_user, _params, session, socket) do
    socket = assign_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        |> put_flash(:error, "You must log in to access this page.")
        |> redirect(to: "/users/log_in")

      {:halt, socket}
    end
  end

  def on_mount(:require_admin, _params, session, socket) do
    socket = assign_current_user(socket, session)

    if socket.assigns.current_user && Policies.admin?(socket.assigns.current_user) do
      {:cont, socket}
    else
      socket =
        socket
        |> put_flash(:error, "You are not authorized to access this page.")
        |> redirect(to: "/")

      {:halt, socket}
    end
  end

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, assign_current_user(socket, session)}
  end

  defp assign_current_user(socket, session) do
    case session do
      %{"user_token" => user_token} ->
        assign_new(socket, :current_user, fn ->
          Accounts.get_user_by_session_token(user_token)
        end)

      %{} ->
        assign_new(socket, :current_user, fn -> nil end)
    end
  end

  @doc """
  Helper function to check authorization in LiveView.
  """
  def authorized?(socket, action, resource \\ nil) do
    user = socket.assigns[:current_user]

    case Policies.authorize(action, user, resource) do
      :ok -> true
      {:error, :unauthorized} -> false
    end
  end
end
