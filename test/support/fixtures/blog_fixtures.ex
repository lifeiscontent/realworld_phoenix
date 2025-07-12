defmodule Realworld.BlogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Realworld.Blog` context.
  """

  @doc """
  Generate a article.
  """
  def article_fixture(attrs \\ %{}) do
    user = attrs[:user] || Realworld.AccountsFixtures.user_fixture()
    
    {:ok, article} =
      attrs
      |> Enum.into(%{
        body: "some body",
        status: "published",
        title: "some title",
        user_id: user.id
      })
      |> Realworld.Blog.create_article()

    # Preload the same associations as get_article! to ensure consistency
    Realworld.Repo.preload(article, [:user, :tags])
  end

  @doc """
  Generate a comment.
  """
  def comment_fixture(attrs \\ %{}) do
    user = attrs[:user] || Realworld.AccountsFixtures.user_fixture()
    article = attrs[:article] || article_fixture()
    
    {:ok, comment} =
      attrs
      |> Enum.into(%{
        content: "some content",
        user_id: user.id,
        article_id: article.id
      })
      |> Realworld.Blog.create_comment()

    # Preload the same associations as get_comment! to ensure consistency
    Realworld.Repo.preload(comment, :user)
  end
end
