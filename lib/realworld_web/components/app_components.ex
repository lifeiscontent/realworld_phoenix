defmodule RealworldWeb.AppComponents do
  @moduledoc """
  Provides domain-specific UI components for the Realworld application.

  These components are built on top of the core components and provide
  consistent UI patterns specific to the application's domain.
  """
  use Phoenix.Component
  use Gettext, backend: RealworldWeb.Gettext

  import RealworldWeb.CoreComponents
  alias Phoenix.LiveView.JS
  alias Realworld.Policies

  # Import routes helper
  use Phoenix.VerifiedRoutes,
    endpoint: RealworldWeb.Endpoint,
    router: RealworldWeb.Router,
    statics: RealworldWeb.static_paths()

  @doc """
  Renders a user avatar with fallback.

  ## Examples

      <.user_avatar user={@user} />
      <.user_avatar user={@user} size="lg" />
      <.user_avatar user={@user} link={true} />
  """
  attr :user, :map, required: true
  attr :size, :string, default: "md", values: ~w(sm md lg)
  attr :link, :boolean, default: false
  attr :class, :string, default: nil

  def user_avatar(assigns) do
    size_classes =
      case assigns.size do
        "sm" -> "w-8 h-8 text-sm"
        "md" -> "w-10 h-10 text-base"
        "lg" -> "w-24 h-24 text-4xl"
      end

    assigns = assign(assigns, :size_classes, size_classes)

    ~H"""
    <%= if @link do %>
      <.link navigate={~p"/profiles/#{@user}"} class={@class}>
        <.avatar_image user={@user} size_classes={@size_classes} />
      </.link>
    <% else %>
      <.avatar_image user={@user} size_classes={@size_classes} class={@class} />
    <% end %>
    """
  end

  attr :user, :map, required: true
  attr :size_classes, :string, required: true
  attr :class, :string, default: nil

  defp avatar_image(assigns) do
    ~H"""
    <%= if @user.image do %>
      <img
        src={@user.image}
        alt={@user.username}
        class={["rounded-full object-cover", @size_classes, @class]}
      />
    <% else %>
      <div class={["rounded-full bg-gray-300 flex items-center justify-center", @size_classes, @class]}>
        <span class="text-gray-500">{String.first(@user.username) |> String.upcase()}</span>
      </div>
    <% end %>
    """
  end

  @doc """
  Renders an article card for list displays.

  ## Examples

      <.article_card article={article} current_user={@current_user} />
  """
  attr :article, :map, required: true
  attr :current_user, :map, default: nil
  attr :on_delete, :any, default: nil
  attr :id, :string, required: true
  attr :live_action, :atom, default: :index

  def article_card(assigns) do
    ~H"""
    <article id={@id} class="border rounded-lg p-6">
      <div class="flex items-center mb-6">
        <.user_avatar user={@article.user} link={true} class="mr-4" />
        <div>
          <.link
            navigate={~p"/profiles/#{@article.user}"}
            class="font-semibold hover:underline"
          >
            {@article.user.username}
          </.link>
          <div class="text-sm text-gray-500 mt-1">
            {Calendar.strftime(@article.inserted_at, "%B %d, %Y")}
          </div>
        </div>
      </div>

      <.link navigate={~p"/articles/#{@article}"}>
        <h2 class="text-2xl font-bold mb-3 hover:text-blue-600">{@article.title}</h2>
      </.link>

      <p class="text-gray-700 mb-6 leading-relaxed">
        {String.slice(@article.body || "", 0, 150)}{if String.length(@article.body || "") > 150,
          do: "..."}
      </p>

      <div class="flex items-center justify-between">
        <.article_stats article={@article} />

        <div class="flex items-center gap-4">
          <.tag_list tags={@article.tags} live_action={@live_action} />

          <div class="flex items-center gap-3">
            <.link
              :if={@current_user && Policies.permit?(:update_article, @current_user, @article)}
              patch={~p"/articles/#{@article}/edit"}
              class="text-sm text-blue-600 hover:underline"
            >
              Edit
            </.link>
            <.link
              :if={@current_user && Policies.permit?(:delete_article, @current_user, @article)}
              phx-click={@on_delete || JS.push("delete", value: %{id: @article.id}) |> hide("##{@id}")}
              data-confirm="Are you sure?"
              class="text-sm text-red-600 hover:underline"
            >
              Delete
            </.link>
          </div>
        </div>
      </div>
    </article>
    """
  end

  @doc """
  Renders article statistics (favorites and comments count).
  """
  attr :article, :map, required: true

  def article_stats(assigns) do
    ~H"""
    <div class="flex items-center space-x-4">
      <div class="flex items-center space-x-1 text-gray-600">
        <.icon
          name={if @article.favorited, do: "hero-heart-solid", else: "hero-heart"}
          class="w-5 h-5"
        />
        <span>{@article.favorites_count || 0}</span>
      </div>

      <div class="flex items-center space-x-1 text-gray-600">
        <.icon name="hero-chat-bubble-left-right" class="w-5 h-5" />
        <span>{length(@article.comments || [])}</span>
      </div>
    </div>
    """
  end

  @doc """
  Renders a list of tags.

  ## Examples

      <.tag_list tags={@article.tags} />
      <.tag_list tags={@article.tags} live_action={:following} />
  """
  attr :tags, :list, default: []
  attr :live_action, :atom, default: :index

  def tag_list(assigns) do
    ~H"""
    <div class="flex flex-wrap gap-2">
      <%= for tag <- @tags do %>
        <.link
          navigate={
            case @live_action do
              :following -> ~p"/following/articles?tag=#{tag.name}"
              _ -> ~p"/articles?tag=#{tag.name}"
            end
          }
          class="text-sm bg-gray-200 px-3 py-1 rounded-full hover:bg-gray-300 transition-colors"
        >
          {tag.name}
        </.link>
      <% end %>
    </div>
    """
  end

  @doc """
  Renders a comment card.

  ## Examples

      <.comment comment={@comment} current_user={@current_user} time_zone={@time_zone} />
  """
  attr :comment, :map, required: true
  attr :current_user, :map, default: nil
  attr :time_zone, :string, required: true
  attr :on_delete, :any, default: JS.push("delete_comment")

  def comment(assigns) do
    ~H"""
    <div class="bg-gray-50 p-4 rounded-lg">
      <div class="flex justify-between items-start">
        <div class="flex items-start space-x-3">
          <.user_avatar user={@comment.user} link={true} />
          <div>
            <.link
              navigate={~p"/profiles/#{@comment.user}"}
              class="font-semibold text-brand hover:underline"
            >
              @{@comment.user.username}
            </.link>
            <span class="text-sm text-gray-600 ml-2">
              {format_datetime(@comment.inserted_at, @time_zone)}
            </span>
          </div>
        </div>
        <.button
          :if={@current_user && Policies.permit?(:delete_comment, @current_user, @comment)}
          phx-click={@on_delete}
          phx-value-id={@comment.id}
          data-confirm="Are you sure you want to delete this comment?"
          variant="danger"
          class="text-sm py-1 px-2"
        >
          Delete
        </.button>
      </div>
      <p class="mt-2 whitespace-pre-wrap">{@comment.content}</p>
    </div>
    """
  end

  # Helper function
  defp format_datetime(datetime, time_zone) do
    datetime
    |> DateTime.shift_zone!(time_zone)
    |> Calendar.strftime("%B %d, %Y at %I:%M %p")
  end
end
