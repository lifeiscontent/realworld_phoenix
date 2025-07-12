defmodule Realworld.Blog.Article do
  use Ecto.Schema
  import Ecto.Changeset
  import Slugy

  @derive {Phoenix.Param, key: :slug}
  schema "articles" do
    field :status, :string, default: "draft"
    field :title, :string
    field :slug, :string
    field :body, :string
    field :favorites_count, :integer, virtual: true, default: 0
    field :favorited, :boolean, virtual: true, default: false

    belongs_to :user, Realworld.Accounts.User
    has_many :comments, Realworld.Blog.Comment
    has_many :favorites, Realworld.Blog.ArticleFavorite
    has_many :favorited_by, through: [:favorites, :user]

    many_to_many :tags, Realworld.Blog.Tag,
      join_through: "article_tags",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, [:title, :body, :status, :user_id])
    |> validate_required([:title, :body, :status, :user_id])
    |> validate_inclusion(:status, ["draft", "published", "archived"])
    |> foreign_key_constraint(:user_id)
    |> slugify(:title)
    |> unique_constraint(:slug)
  end
end
