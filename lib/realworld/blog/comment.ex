defmodule Realworld.Blog.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :content, :string

    belongs_to :user, Realworld.Accounts.User
    belongs_to :article, Realworld.Blog.Article

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content, :user_id, :article_id])
    |> validate_required([:content, :user_id, :article_id])
    |> validate_length(:content, min: 1, max: 1000)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:article_id)
  end
end
