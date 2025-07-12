defmodule Realworld.Blog.ArticleTag do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "article_tags" do
    belongs_to :article, Realworld.Blog.Article, primary_key: true
    belongs_to :tag, Realworld.Blog.Tag, primary_key: true

    timestamps(updated_at: false, type: :utc_datetime)
  end

  @doc false
  def changeset(article_tag, attrs) do
    article_tag
    |> cast(attrs, [:article_id, :tag_id])
    |> validate_required([:article_id, :tag_id])
    |> foreign_key_constraint(:article_id)
    |> foreign_key_constraint(:tag_id)
    |> unique_constraint([:article_id, :tag_id])
  end
end
