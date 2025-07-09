defmodule RealworldWeb.Plugs.Authorize do
  @moduledoc """
  Plug for authorizing actions in controllers.
  
  Usage in controllers:
  
      plug RealworldWeb.Plugs.Authorize, :admin when action in [:index, :delete]
      plug RealworldWeb.Plugs.Authorize, {:owns, :post} when action in [:edit, :update]
  """
  import Plug.Conn
  import Phoenix.Controller
  
  alias Realworld.Policies

  def init(opts), do: opts

  def call(conn, :admin) do
    user = conn.assigns[:current_user]
    
    if user && Policies.admin?(user) do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorized to perform this action.")
      |> redirect(to: "/")
      |> halt()
    end
  end

  def call(conn, {:owns, resource_key}) do
    user = conn.assigns[:current_user]
    resource = conn.assigns[resource_key]
    
    if user && resource && Policies.owns?(user, resource) do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorized to perform this action.")
      |> redirect(to: "/")
      |> halt()
    end
  end

  def call(conn, {action, resource_key}) do
    user = conn.assigns[:current_user]
    resource = conn.assigns[resource_key]
    
    case Policies.authorize(action, user, resource) do
      :ok -> 
        conn
      {:error, :unauthorized} ->
        conn
        |> put_flash(:error, "You are not authorized to perform this action.")
        |> redirect(to: "/")
        |> halt()
    end
  end
end