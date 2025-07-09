defmodule RealworldWeb.ArticleLive.Index do
  use RealworldWeb, :live_view

  alias Realworld.Blog
  alias Realworld.Blog.Article
  alias Realworld.Policies

  on_mount RealworldWeb.AuthLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    # Global feed - all published articles
    articles = Blog.list_articles(socket.assigns.current_user)
    
    socket
    |> assign(:page_title, "Global Feed")
    |> stream(:articles, articles)
    |> assign(:article, nil)
  end

  defp apply_action(socket, :following, _params) do
    # Following feed - articles from followed users
    articles = Blog.list_following_articles(socket.assigns.current_user)
    
    socket
    |> assign(:page_title, "Following")
    |> stream(:articles, articles)
    |> assign(:article, nil)
  end

  defp apply_action(socket, :edit, %{"slug" => slug}) do
    article = Blog.get_article_by_slug!(slug)
    current_user = socket.assigns.current_user
    
    case Policies.authorize(:update_article, current_user, article) do
      :ok ->
        socket
        |> assign(:page_title, "Edit Article")
        |> assign(:article, article)
      
      {:error, :unauthorized} ->
        socket
        |> put_flash(:error, "You are not authorized to edit this article.")
        |> push_navigate(to: ~p"/articles")
    end
  end

  defp apply_action(socket, :new, _params) do
    current_user = socket.assigns.current_user
    
    case Policies.authorize(:create_article, current_user, nil) do
      :ok ->
        socket
        |> assign(:page_title, "New Article")
        |> assign(:article, %Article{user_id: current_user.id})
      
      {:error, :unauthorized} ->
        socket
        |> put_flash(:error, "You are not authorized to create articles.")
        |> push_navigate(to: ~p"/articles")
    end
  end

  @impl true
  def handle_info({RealworldWeb.ArticleLive.FormComponent, {:saved, article}}, socket) do
    {:noreply, stream_insert(socket, :articles, article)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    article = Blog.get_article!(id)
    current_user = socket.assigns.current_user
    
    case Policies.authorize(:delete_article, current_user, article) do
      :ok ->
        {:ok, _} = Blog.delete_article(article)
        {:noreply, stream_delete(socket, :articles, article)}
      
      {:error, :unauthorized} ->
        socket =
          socket
          |> put_flash(:error, "You are not authorized to delete this article.")
        
        {:noreply, socket}
    end
  end
end
