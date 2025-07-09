defmodule RealworldWeb.ArticleLiveTest do
  use RealworldWeb.ConnCase

  import Phoenix.LiveViewTest
  import Realworld.BlogFixtures
  import Realworld.AccountsFixtures

  @create_attrs %{status: "published", title: "new article title", body: "some body"}
  @update_attrs %{
    status: "draft",
    title: "some title",
    body: "some updated body"
  }
  @invalid_attrs %{status: "draft", title: nil, body: nil}

  defp create_article(_) do
    user = user_fixture()
    article = article_fixture(user: user)
    %{article: article, user: user}
  end

  describe "Index" do
    setup [:create_article]

    test "lists all articles", %{conn: conn, article: article} do
      {:ok, _index_live, html} = live(conn, ~p"/articles")

      assert html =~ "Global Feed"
      assert html =~ article.title
    end

    test "saves new article", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      
      {:ok, index_live, _html} = live(conn, ~p"/articles")

      assert index_live |> element("a", "New Article") |> render_click() =~
               "New Article"

      assert_patch(index_live, ~p"/articles/new")

      assert index_live
             |> form("#article-form", article: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#article-form", article: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/articles")

      html = render(index_live)
      assert html =~ "Article created successfully"
      assert html =~ "new article title"
    end

    test "updates article in listing", %{conn: conn, article: article, user: user} do
      conn = log_in_user(conn, user)
      
      {:ok, index_live, _html} = live(conn, ~p"/articles")

      assert index_live |> element("#articles-#{article.id} a", "Edit") |> render_click() =~
               "Edit Article"

      assert_patch(index_live, ~p"/articles/#{article}/edit")

      assert index_live
             |> form("#article-form", article: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#article-form", article: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/articles")

      html = render(index_live)
      assert html =~ "Article updated successfully"
      assert html =~ "some updated body"
    end

    test "deletes article in listing", %{conn: conn, article: article, user: user} do
      conn = log_in_user(conn, user)
      
      {:ok, index_live, _html} = live(conn, ~p"/articles")

      assert index_live |> element("#articles-#{article.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#articles-#{article.id}")
    end
  end

  describe "Show" do
    setup [:create_article]

    test "displays article", %{conn: conn, article: article} do
      {:ok, _show_live, html} = live(conn, ~p"/articles/#{article}")

      assert html =~ article.title
      assert html =~ article.body
    end

    test "updates article within modal", %{conn: conn, article: article, user: user} do
      conn = log_in_user(conn, user)
      
      {:ok, show_live, _html} = live(conn, ~p"/articles/#{article}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Article"

      assert_patch(show_live, ~p"/articles/#{article}/show/edit")

      assert show_live
             |> form("#article-form", article: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#article-form", article: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/articles/#{article}")

      html = render(show_live)
      assert html =~ "Article updated successfully"
      assert html =~ "some updated body"
    end
  end
end
