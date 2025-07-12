defmodule Realworld.BlogTest do
  use Realworld.DataCase

  alias Realworld.Blog

  describe "articles" do
    alias Realworld.Blog.Article

    import Realworld.BlogFixtures

    @invalid_attrs %{status: nil, title: nil, body: nil}
    @invalid_comment_attrs %{content: nil, user_id: nil, article_id: nil}

    test "list_articles/0 returns all articles" do
      article = article_fixture()
      articles = Blog.list_articles()
      assert Enum.any?(articles, fn a -> a.id == article.id end)
    end

    test "get_article!/1 returns the article with given id" do
      article = article_fixture()
      retrieved_article = Blog.get_article!(article.id)
      assert retrieved_article.id == article.id
      assert retrieved_article.title == article.title
      assert retrieved_article.body == article.body
      assert retrieved_article.status == article.status
    end

    test "create_article/1 with valid data creates a article" do
      user = Realworld.AccountsFixtures.user_fixture()
      valid_attrs = %{status: "published", title: "some title", body: "some body", user_id: user.id}

      assert {:ok, %Article{} = article} = Blog.create_article(valid_attrs)
      assert article.status == "published"
      assert article.title == "some title"
      assert article.body == "some body"
      assert article.user_id == user.id
    end

    test "create_article/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Blog.create_article(@invalid_attrs)
    end

    test "update_article/2 with valid data updates the article" do
      article = article_fixture()

      update_attrs = %{
        status: "draft",
        title: "some updated title",
        body: "some updated body"
      }

      assert {:ok, %Article{} = article} = Blog.update_article(article, update_attrs)
      assert article.status == "draft"
      assert article.title == "some updated title"
      assert article.body == "some updated body"
    end

    test "update_article/2 with invalid data returns error changeset" do
      article = article_fixture()
      assert {:error, %Ecto.Changeset{}} = Blog.update_article(article, @invalid_attrs)
      retrieved_article = Blog.get_article!(article.id)
      assert retrieved_article.id == article.id
      assert retrieved_article.title == article.title
      assert retrieved_article.body == article.body
      assert retrieved_article.status == article.status
    end

    test "delete_article/1 deletes the article" do
      article = article_fixture()
      assert {:ok, %Article{}} = Blog.delete_article(article)
      assert_raise Ecto.NoResultsError, fn -> Blog.get_article!(article.id) end
    end

    test "change_article/1 returns a article changeset" do
      article = article_fixture()
      assert %Ecto.Changeset{} = Blog.change_article(article)
    end
  end

  describe "comments" do
    alias Realworld.Blog.Comment

    import Realworld.BlogFixtures

    test "list_comments/0 returns all comments" do
      comment = comment_fixture()
      comments = Blog.list_comments()
      assert Enum.any?(comments, fn c -> c.id == comment.id end)
    end

    test "get_comment!/1 returns the comment with given id" do
      comment = comment_fixture()
      retrieved_comment = Blog.get_comment!(comment.id)
      assert retrieved_comment.id == comment.id
      assert retrieved_comment.content == comment.content
      assert retrieved_comment.user_id == comment.user_id
      assert retrieved_comment.article_id == comment.article_id
    end

    test "create_comment/1 with valid data creates a comment" do
      user = Realworld.AccountsFixtures.user_fixture()
      article = article_fixture()
      valid_attrs = %{content: "some content", user_id: user.id, article_id: article.id}

      assert {:ok, %Comment{} = comment} = Blog.create_comment(valid_attrs)
      assert comment.content == "some content"
      assert comment.user_id == user.id
      assert comment.article_id == article.id
    end

    test "create_comment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Blog.create_comment(@invalid_comment_attrs)
    end

    test "update_comment/2 with valid data updates the comment" do
      comment = comment_fixture()
      update_attrs = %{content: "some updated content"}

      assert {:ok, %Comment{} = comment} = Blog.update_comment(comment, update_attrs)
      assert comment.content == "some updated content"
    end

    test "update_comment/2 with invalid data returns error changeset" do
      comment = comment_fixture()
      assert {:error, %Ecto.Changeset{}} = Blog.update_comment(comment, @invalid_comment_attrs)
      retrieved_comment = Blog.get_comment!(comment.id)
      assert retrieved_comment.id == comment.id
      assert retrieved_comment.content == comment.content
      assert retrieved_comment.user_id == comment.user_id
      assert retrieved_comment.article_id == comment.article_id
    end

    test "delete_comment/1 deletes the comment" do
      comment = comment_fixture()
      assert {:ok, %Comment{}} = Blog.delete_comment(comment)
      assert_raise Ecto.NoResultsError, fn -> Blog.get_comment!(comment.id) end
    end

    test "change_comment/1 returns a comment changeset" do
      comment = comment_fixture()
      assert %Ecto.Changeset{} = Blog.change_comment(comment)
    end
  end
end
