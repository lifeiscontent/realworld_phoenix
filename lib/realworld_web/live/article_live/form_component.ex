defmodule RealworldWeb.ArticleLive.FormComponent do
  use RealworldWeb, :live_component

  alias Realworld.Blog
  alias Realworld.Policies
  alias Realworld.Repo

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage article records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="article-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:user_id]} type="hidden" />
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:body]} type="textarea" label="Body" rows="10" />
        <.input field={@form[:status]} type="select" label="Status" 
          options={[{"Draft", "draft"}, {"Published", "published"}, {"Archived", "archived"}]} />
        <:actions>
          <.button phx-disable-with="Saving...">Save Article</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{article: article} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Blog.change_article(article))
     end)}
  end

  @impl true
  def handle_event("validate", %{"article" => article_params}, socket) do
    changeset = Blog.change_article(socket.assigns.article, article_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"article" => article_params}, socket) do
    save_article(socket, socket.assigns.action, article_params)
  end

  defp save_article(socket, :edit, article_params) do
    case Blog.update_article(socket.assigns.article, article_params) do
      {:ok, article} ->
        article = Repo.preload(article, [:user, :comments])
        notify_parent({:saved, article})

        {:noreply,
         socket
         |> put_flash(:info, "Article updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_article(socket, :new, article_params) do
    current_user = socket.assigns.current_user
    
    case Policies.authorize(:create_article, current_user, article_params) do
      :ok ->
        case Blog.create_article(article_params) do
          {:ok, article} ->
            article = Repo.preload(article, [:user, :comments])
            notify_parent({:saved, article})

            {:noreply,
             socket
             |> put_flash(:info, "Article created successfully")
             |> push_patch(to: socket.assigns.patch)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, form: to_form(changeset))}
        end
        
      {:error, :unauthorized} ->
        changeset = 
          socket.assigns.article
          |> Blog.change_article(article_params)
          |> Ecto.Changeset.add_error(:user_id, "You can only create articles for yourself")
          |> Map.put(:action, :validate)
        
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
