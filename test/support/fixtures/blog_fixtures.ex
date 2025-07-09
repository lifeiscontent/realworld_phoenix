defmodule Realworld.BlogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Realworld.Blog` context.
  """

  @doc """
  Generate a article.
  """
  def article_fixture(attrs \\ %{}) do
    {:ok, article} =
      attrs
      |> Enum.into(%{
        body: "some body",
        status: "some status",
        title: "some title"
      })
      |> Realworld.Blog.create_article()

    article
  end

  @doc """
  Generate a comment.
  """
  def comment_fixture(attrs \\ %{}) do
    {:ok, comment} =
      attrs
      |> Enum.into(%{
        content: "some content"
      })
      |> Realworld.Blog.create_comment()

    comment
  end
end
