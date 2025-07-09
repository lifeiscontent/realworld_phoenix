defmodule RealworldWeb.ProfileLive.Show do
  use RealworldWeb, :live_view

  alias Realworld.Accounts
  alias Realworld.Blog
  alias Realworld.Policies

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
        current_user = socket.assigns.current_user
        articles = Blog.list_user_articles(user, current_user)
        
        following = current_user && Accounts.following?(current_user, user)
        followers_count = Accounts.get_followers_count(user)
        following_count = Accounts.get_following_count(user)
          
        {:ok,
         socket
         |> assign(:page_title, "@#{user.username}")
         |> assign(:user, user)
         |> assign(:following, following)
         |> assign(:followers_count, followers_count)
         |> assign(:following_count, following_count)
         |> assign(:can_follow?, Policies.permit?(:follow_user, current_user, user))
         |> stream(:articles, articles)}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    article = Blog.get_article!(id)
    current_user = socket.assigns.current_user

    case Policies.authorize(:delete_article, current_user, article) do
      :ok ->
        {:ok, _} = Blog.delete_article(article)
        
        {:noreply,
         socket
         |> stream_delete(:articles, article)
         |> put_flash(:info, "Article deleted successfully")}
      
      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You are not authorized to delete this article")}
    end
  end

  @impl true
  def handle_event("toggle_follow", _params, socket) do
    current_user = socket.assigns.current_user
    user = socket.assigns.user
    
    if current_user do
      result = if socket.assigns.following do
        Accounts.unfollow_user(current_user, user)
      else
        Accounts.follow_user(current_user, user)
      end
      
      case result do
        {:ok, _} ->
          following = Accounts.following?(current_user, user)
          followers_count = Accounts.get_followers_count(user)
          
          {:noreply, 
           socket
           |> assign(:following, following)
           |> assign(:followers_count, followers_count)}
        
        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Failed to update follow status")}
      end
    else
      {:noreply, 
       socket
       |> put_flash(:error, "You must be logged in to follow users")
       |> push_navigate(to: ~p"/users/log_in")}
    end
  end
end