defmodule Realworld.Blog.Article do
  use Ecto.Schema
  import Ecto.Changeset

  schema "articles" do
    field :status, :string, default: "draft"
    field :title, :string
    field :body, :string
    
    belongs_to :user, Realworld.Accounts.User
    has_many :comments, Realworld.Blog.Comment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, [:title, :body, :status, :user_id])
    |> validate_required([:title, :body, :status, :user_id])
    |> validate_inclusion(:status, ["draft", "published", "archived"])
    |> foreign_key_constraint(:user_id)
  end
end
