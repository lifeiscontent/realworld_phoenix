defmodule Realworld.Blog.ArticleFavorite do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "article_favorites" do
    belongs_to :user, Realworld.Accounts.User
    belongs_to :article, Realworld.Blog.Article

    timestamps(updated_at: false, type: :utc_datetime)
  end

  @doc false
  def changeset(article_favorite, attrs) do
    article_favorite
    |> cast(attrs, [:user_id, :article_id])
    |> validate_required([:user_id, :article_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:article_id)
    |> unique_constraint([:user_id, :article_id])
  end
end