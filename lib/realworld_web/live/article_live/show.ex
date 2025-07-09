defmodule RealworldWeb.ArticleLive.Show do
  use RealworldWeb, :live_view

  alias Realworld.Blog
  alias Realworld.Blog.Comment
  alias Realworld.Policies

  on_mount RealworldWeb.AuthLive
  on_mount RealworldWeb.TimeZoneLive

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    article = Blog.get_article!(id)
    current_user = socket.assigns.current_user
    
    case Policies.authorize(:view_article, current_user, article) do
      :ok ->
        # Subscribe to comments for this article
        Phoenix.PubSub.subscribe(Realworld.PubSub, "article:#{article.id}:comments")
        
        comments = Blog.list_article_comments(article)
        
        new_comment = %Comment{
          user_id: current_user && current_user.id,
          article_id: article.id
        }
        
        {:noreply,
         socket
         |> assign(:page_title, page_title(socket.assigns.live_action))
         |> assign(:article, article)
         |> stream(:comments, comments)
         |> assign(:comment_form, to_form(Blog.change_comment(new_comment)))
         |> assign(:can_comment?, Policies.permit?(:create_comment, current_user, article))}
      
      {:error, :unauthorized} ->
        socket =
          socket
          |> put_flash(:error, "You are not authorized to view this article.")
          |> push_navigate(to: ~p"/articles")
        
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save_comment", %{"comment" => comment_params}, socket) do
    current_user = socket.assigns.current_user
    article = socket.assigns.article
    
    case Policies.authorize(:create_comment, current_user, comment_params) do
      :ok ->
        case Blog.create_comment(comment_params) do
          {:ok, comment} ->
            comment = Blog.get_comment!(comment.id) # Reload with preloads
            
            # Broadcast the new comment to all subscribers
            Phoenix.PubSub.broadcast(
              Realworld.PubSub,
              "article:#{article.id}:comments",
              {:new_comment, comment}
            )
            
            # Create a completely fresh comment form with empty content
            new_comment_form = 
              %Comment{
                user_id: current_user.id,
                article_id: article.id
              }
              |> Blog.change_comment(%{"content" => ""})
              |> to_form()
            
            {:noreply,
             socket
             |> stream_insert(:comments, comment, at: 0)
             |> assign(:comment_form, new_comment_form)
             |> put_flash(:info, "Comment posted successfully")}
          
          {:error, changeset} ->
            {:noreply, assign(socket, :comment_form, to_form(changeset))}
        end
        
      {:error, :unauthorized} ->
        changeset = 
          %Comment{}
          |> Blog.change_comment(comment_params)
          |> Ecto.Changeset.add_error(:user_id, "You can only create comments for yourself")
          |> Map.put(:action, :validate)
        
        {:noreply, assign(socket, :comment_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete_comment", %{"id" => comment_id}, socket) do
    comment = Blog.get_comment!(comment_id)
    current_user = socket.assigns.current_user
    
    case Policies.authorize(:delete_comment, current_user, comment) do
      :ok ->
        {:ok, _} = Blog.delete_comment(comment)
        
        # Broadcast the comment deletion to all subscribers
        Phoenix.PubSub.broadcast(
          Realworld.PubSub,
          "article:#{socket.assigns.article.id}:comments",
          {:delete_comment, comment}
        )
        
        {:noreply,
         socket
         |> stream_delete(:comments, comment)
         |> put_flash(:info, "Comment deleted successfully")}
      
      {:error, :unauthorized} ->
        {:noreply, put_flash(socket, :error, "You can only delete your own comments")}
    end
  end

  @impl true
  def handle_info({:new_comment, comment}, socket) do
    # Only insert the comment if it's not from the current user (to avoid duplicates)
    current_user_id = socket.assigns.current_user && socket.assigns.current_user.id
    
    if comment.user_id != current_user_id do
      {:noreply, stream_insert(socket, :comments, comment, at: 0)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:delete_comment, comment}, socket) do
    # Only delete the comment if it's not from the current user (to avoid duplicates)
    current_user_id = socket.assigns.current_user && socket.assigns.current_user.id
    
    if comment.user_id != current_user_id do
      {:noreply, stream_delete(socket, :comments, comment)}
    else
      {:noreply, socket}
    end
  end

  defp page_title(:show), do: "Show Article"
  defp page_title(:edit), do: "Edit Article"
  
  defp format_datetime(datetime, time_zone) do
    case DateTime.shift_zone(datetime, time_zone) do
      {:ok, local_datetime} ->
        Calendar.strftime(local_datetime, "%B %d, %Y at %I:%M %p")
      
      {:error, _} ->
        # Fallback to UTC if timezone conversion fails
        Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p UTC")
    end
  end
end
