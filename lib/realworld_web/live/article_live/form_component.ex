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
        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          options={[{"Draft", "draft"}, {"Published", "published"}, {"Archived", "archived"}]}
        />
        <.input
          name="tags"
          type="text"
          label="Tags"
          value={@tag_names}
          placeholder="Comma-separated tags (e.g., elixir, phoenix, tutorial)"
          phx-debounce="300"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Article</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{article: article} = assigns, socket) do
    article = Repo.preload(article, :tags)
    tag_names = Enum.map(article.tags, & &1.name) |> Enum.join(", ")

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:tag_names, tag_names)
     |> assign_new(:form, fn ->
       to_form(Blog.change_article(article))
     end)}
  end

  @impl true
  def handle_event("validate", %{"article" => article_params} = params, socket) do
    tag_names = Map.get(params, "tags", "")
    changeset = Blog.change_article(socket.assigns.article, article_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate), tag_names: tag_names)}
  end

  def handle_event("save", %{"article" => article_params} = params, socket) do
    tag_names = Map.get(params, "tags", "")
    save_article(socket, socket.assigns.action, article_params, tag_names)
  end

  defp save_article(socket, :edit, article_params, tag_names) do
    case Blog.update_article(socket.assigns.article, article_params) do
      {:ok, article} ->
        # Update tags
        tag_list = parse_tags(tag_names)
        {:ok, article} = Blog.update_article_tags(article, tag_list)

        article = Repo.preload(article, [:user, :comments, :tags])
        notify_parent({:saved, article})

        {:noreply,
         socket
         |> put_flash(:info, "Article updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_article(socket, :new, article_params, tag_names) do
    current_user = socket.assigns.current_user

    case Policies.authorize(:create_article, current_user, article_params) do
      :ok ->
        case Blog.create_article(article_params) do
          {:ok, article} ->
            # Update tags
            tag_list = parse_tags(tag_names)
            {:ok, article} = Blog.update_article_tags(article, tag_list)

            article = Repo.preload(article, [:user, :comments, :tags])
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

  defp parse_tags(tag_string) do
    tag_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
