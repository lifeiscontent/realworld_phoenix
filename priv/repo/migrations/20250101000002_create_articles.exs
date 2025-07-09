defmodule Realworld.Repo.Migrations.CreateArticles do
  use Ecto.Migration

  def change do
    create table(:articles) do
      add :title, :string
      add :body, :text
      add :status, :string
      add :slug, :citext, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:articles, [:user_id])
    create index(:articles, [:status])
    create unique_index(:articles, [:slug])
  end
end
