defmodule Realworld.Blog.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tags" do
    field :name, :string

    many_to_many :articles, Realworld.Blog.Article,
      join_through: "article_tags",
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> validate_length(:name, min: 1, max: 50)
    |> validate_format(:name, ~r/^[a-zA-Z0-9]+$/, message: "can only contain letters and numbers")
    |> unique_constraint(:name)
  end
end
