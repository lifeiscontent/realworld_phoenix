defmodule Realworld.Repo.Migrations.AddSlugToArticles do
  use Ecto.Migration

  def up do
    alter table(:articles) do
      add :slug, :string
    end

    # Generate slugs for existing articles
    execute """
    UPDATE articles 
    SET slug = LOWER(REPLACE(REPLACE(title, ' ', '-'), '.', '')) || '-' || id::text
    WHERE slug IS NULL
    """

    # Now make it NOT NULL
    alter table(:articles) do
      modify :slug, :string, null: false
    end

    create unique_index(:articles, [:slug])
  end

  def down do
    drop index(:articles, [:slug])
    
    alter table(:articles) do
      remove :slug
    end
  end
end