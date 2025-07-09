defmodule Realworld.Blog do
  @moduledoc """
  The Blog context.
  """

  import Ecto.Query, warn: false
  alias Realworld.Repo

  alias Realworld.Blog.Article
  alias Realworld.Blog.ArticleFavorite
  alias Realworld.Accounts.User

  @doc """
  Returns the list of articles.

  ## Examples

      iex> list_articles()
      [%Article{}, ...]

  """
  def list_articles do
    Repo.all(Article)
  end

  @doc """
  Returns the list of articles for a specific user.

  ## Examples

      iex> list_user_articles(user)
      [%Article{}, ...]

  """
  def list_user_articles(%{id: user_id}) do
    Article
    |> where(user_id: ^user_id)
    |> order_by(desc: :inserted_at)
    |> preload([:user, :comments])
    |> Repo.all()
  end

  @doc """
  Returns the list of articles visible to a specific user.
  
  - Admins can see all articles
  - Authenticated users can see their own articles and published articles
  - Unauthenticated users can only see published articles
  """
  def list_user_visible_articles(user) do
    Article
    |> filter_by_user_visibility(user)
    |> preload(:user)
    |> Repo.all()
    |> Repo.preload(:comments)
  end

  defp filter_by_user_visibility(query, %User{role: "admin"}), do: query
  
  defp filter_by_user_visibility(query, %User{id: user_id}) do
    from a in query,
      where: a.user_id == ^user_id or a.status == "published"
  end
  
  defp filter_by_user_visibility(query, nil) do
    from a in query, where: a.status == "published"
  end

  @doc """
  Gets a single article.

  Raises `Ecto.NoResultsError` if the Article does not exist.

  ## Examples

      iex> get_article!(123)
      %Article{}

      iex> get_article!(456)
      ** (Ecto.NoResultsError)

  """
  def get_article!(id) do
    Article
    |> Repo.get!(id)
    |> Repo.preload(:user)
  end

  @doc """
  Gets a single article by slug.

  Raises `Ecto.NoResultsError` if the Article does not exist.

  ## Examples

      iex> get_article_by_slug!("my-article")
      %Article{}

      iex> get_article_by_slug!("nonexistent")
      ** (Ecto.NoResultsError)

  """
  def get_article_by_slug!(slug) do
    Article
    |> Repo.get_by!(slug: slug)
    |> Repo.preload(:user)
  end

  @doc """
  Creates a article.

  ## Examples

      iex> create_article(%{field: value})
      {:ok, %Article{}}

      iex> create_article(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_article(attrs \\ %{}) do
    %Article{}
    |> Article.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a article.

  ## Examples

      iex> update_article(article, %{field: new_value})
      {:ok, %Article{}}

      iex> update_article(article, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_article(%Article{} = article, attrs) do
    article
    |> Article.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a article.

  ## Examples

      iex> delete_article(article)
      {:ok, %Article{}}

      iex> delete_article(article)
      {:error, %Ecto.Changeset{}}

  """
  def delete_article(%Article{} = article) do
    Repo.delete(article)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking article changes.

  ## Examples

      iex> change_article(article)
      %Ecto.Changeset{data: %Article{}}

  """
  def change_article(%Article{} = article, attrs \\ %{}) do
    Article.changeset(article, attrs)
  end

  alias Realworld.Blog.Comment

  @doc """
  Returns the list of comments.

  ## Examples

      iex> list_comments()
      [%Comment{}, ...]

  """
  def list_comments do
    Repo.all(Comment)
  end

  @doc """
  Returns the list of comments for a specific article.
  """
  def list_article_comments(%Article{id: article_id}) do
    Comment
    |> where([c], c.article_id == ^article_id)
    |> order_by([c], desc: c.inserted_at)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Gets a single comment.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_comment!(id) do
    Comment
    |> Repo.get!(id)
    |> Repo.preload(:user)
  end

  @doc """
  Creates a comment.

  ## Examples

      iex> create_comment(%{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs \\ %{}) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a comment.

  ## Examples

      iex> update_comment(comment, %{field: new_value})
      {:ok, %Comment{}}

      iex> update_comment(comment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a comment.

  ## Examples

      iex> delete_comment(comment)
      {:ok, %Comment{}}

      iex> delete_comment(comment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{data: %Comment{}}

  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  @doc """
  Favorites an article for a user.
  """
  def favorite_article(%User{id: user_id}, %Article{id: article_id}) do
    %ArticleFavorite{}
    |> ArticleFavorite.changeset(%{user_id: user_id, article_id: article_id})
    |> Repo.insert()
    |> case do
      {:ok, _} -> {:ok, get_article!(article_id)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Unfavorites an article for a user.
  """
  def unfavorite_article(%User{id: user_id}, %Article{id: article_id}) do
    query = from f in ArticleFavorite,
      where: f.user_id == ^user_id and f.article_id == ^article_id
    
    case Repo.delete_all(query) do
      {0, _} -> {:error, :not_found}
      {_, _} -> {:ok, get_article!(article_id)}
    end
  end

  @doc """
  Checks if a user has favorited an article.
  """
  def favorited?(%User{id: user_id}, %Article{id: article_id}) do
    ArticleFavorite
    |> where([f], f.user_id == ^user_id and f.article_id == ^article_id)
    |> Repo.exists?()
  end

  def favorited?(nil, _article), do: false

  @doc """
  Gets the favorites count for an article.
  """
  def get_favorites_count(%Article{id: article_id}) do
    ArticleFavorite
    |> where([f], f.article_id == ^article_id)
    |> Repo.aggregate(:count)
  end

  @doc """
  Preloads article with favorites count and favorited status for a user.
  """
  def load_article_stats(%Article{} = article, user) do
    article
    |> Map.put(:favorites_count, get_favorites_count(article))
    |> Map.put(:favorited, favorited?(user, article))
  end

  def load_article_stats(articles, user) when is_list(articles) do
    Enum.map(articles, &load_article_stats(&1, user))
  end
end
