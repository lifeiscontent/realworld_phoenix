defmodule RealworldWeb.ArticleLive.Index do
  use RealworldWeb, :live_view

  alias Realworld.Blog
  alias Realworld.Blog.Article
  alias Realworld.Policies

  on_mount RealworldWeb.AuthLive

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page, 1)
      |> assign(:per_page, 10)
      |> assign(:end_of_feed?, false)
      |> assign(:last_article_id, nil)
      
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, params) do
    # Global feed - all published articles or filtered by tag
    tag_name = params["tag"]
    
    {articles, page_title} = if tag_name do
      {Blog.list_articles_by_tag(tag_name, socket.assigns.current_user, limit: socket.assigns.per_page), 
       "Articles tagged with \"#{tag_name}\""}
    else
      {Blog.list_articles(socket.assigns.current_user, limit: socket.assigns.per_page), 
       "Global Feed"}
    end
    
    last_article_id = case List.last(articles) do
      nil -> nil
      article -> article.id
    end
    
    socket
    |> assign(:page_title, page_title)
    |> assign(:page, 1)
    |> assign(:tag, tag_name)
    |> assign(:end_of_feed?, length(articles) < socket.assigns.per_page)
    |> assign(:last_article_id, last_article_id)
    |> stream(:articles, articles, reset: true)
    |> assign(:article, nil)
  end

  defp apply_action(socket, :following, params) do
    # Following feed - articles from followed users, optionally filtered by tag
    tag_name = params["tag"]
    
    {articles, page_title} = if tag_name do
      {Blog.list_following_articles_by_tag(tag_name, socket.assigns.current_user, limit: socket.assigns.per_page), 
       "Following - Tagged with \"#{tag_name}\""}
    else
      {Blog.list_following_articles(socket.assigns.current_user, limit: socket.assigns.per_page), 
       "Following"}
    end
    
    last_article_id = case List.last(articles) do
      nil -> nil
      article -> article.id
    end
    
    socket
    |> assign(:page_title, page_title)
    |> assign(:page, 1)
    |> assign(:tag, tag_name)
    |> assign(:end_of_feed?, length(articles) < socket.assigns.per_page)
    |> assign(:last_article_id, last_article_id)
    |> stream(:articles, articles, reset: true)
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

  @impl true
  def handle_event("next-page", _params, socket) do
    %{current_user: current_user, live_action: action, page: page, per_page: per_page, last_article_id: last_article_id} = socket.assigns
    
    # Don't paginate if there's no cursor
    if last_article_id == nil do
      {:noreply, socket}
    else
      opts = [after: last_article_id, limit: per_page]
      
      articles = case {action, socket.assigns[:tag]} do
        {:index, nil} -> 
          Blog.list_articles(current_user, opts)
        {:index, tag_name} -> 
          Blog.list_articles_by_tag(tag_name, current_user, opts)
        {:following, nil} -> 
          Blog.list_following_articles(current_user, opts)
        {:following, tag_name} -> 
          Blog.list_following_articles_by_tag(tag_name, current_user, opts)
        _ -> 
          []
      end
      
      new_last_article_id = case List.last(articles) do
        nil -> last_article_id
        article -> article.id
      end
      
      socket =
        socket
        |> assign(:page, page + 1)
        |> assign(:end_of_feed?, length(articles) < per_page)
        |> assign(:last_article_id, new_last_article_id)
        |> stream(:articles, articles)
      
      {:noreply, socket}
    end
  end
end
