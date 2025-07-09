defmodule RealworldWeb.ProfileLive.Show do
  use RealworldWeb, :live_view

  alias Realworld.Accounts
  alias Realworld.Blog

  on_mount RealworldWeb.AuthLive
  on_mount RealworldWeb.TimeZoneLive

  import RealworldWeb.DateTimeHelpers

  @impl true
  def mount(%{"username" => username}, _session, socket) do
    case Accounts.get_user_by_username(username) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "User not found")
         |> push_navigate(to: ~p"/")}

      user ->
        {:ok,
         socket
         |> assign(:page_title, "@#{user.username}")
         |> assign(:user, user)
         |> stream(:articles, Blog.list_user_articles(user))}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    article = Blog.get_article!(id)
    current_user = socket.assigns.current_user

    if current_user && (current_user.id == article.user_id || current_user.role == "admin") do
      {:ok, _} = Blog.delete_article(article)
      
      {:noreply,
       socket
       |> stream_delete(:articles, article)
       |> put_flash(:info, "Article deleted successfully")}
    else
      {:noreply, put_flash(socket, :error, "You are not authorized to delete this article")}
    end
  end
end