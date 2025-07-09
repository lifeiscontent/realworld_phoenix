defmodule Realworld.Blog do
  @moduledoc """
  The Blog context.
  """

  import Ecto.Query, warn: false
  alias Realworld.Repo

  alias Realworld.Blog.Article
  alias Realworld.Blog.ArticleFavorite
  alias Realworld.Blog.Tag
  alias Realworld.Blog.Comment
  alias Realworld.Accounts.User
  alias Realworld.Policies

  # =====================================
  # Article Functions
  # =====================================

  @doc """
  Returns the list of all published articles.
  Ordered by most recent first.

  ## Options

    * `:after` - cursor for pagination (article ID)
    * `:limit` - number of articles to return (default: 10)

  """
  def list_articles(user \\ nil, opts \\ []) do
    after_cursor = opts[:after]
    limit = opts[:limit] || 10

    query =
      Article
      |> where(status: "published")
      |> order_by(desc: :inserted_at, desc: :id)
      |> limit(^limit)
      |> preload([:user, :tags, :comments])

    query =
      if after_cursor do
        # Get the cursor article to compare timestamps
        cursor_article = Repo.get!(Article, after_cursor)

        from a in query,
          where:
            a.inserted_at < ^cursor_article.inserted_at or
              (a.inserted_at == ^cursor_article.inserted_at and a.id < ^cursor_article.id)
      else
        query
      end

    query
    |> with_stats(user)
    |> Repo.all()
  end

  @doc """
  Returns the list of articles for a specific user.

  Uses policy scope to show:
  - All articles if viewing own profile
  - Only published articles if viewing someone else's profile

  ## Examples

      iex> list_user_articles(user, current_user)
      [%Article{}, ...]

  """
  def list_user_articles(%{id: user_id}, current_user \\ nil) do
    Article
    |> Policies.scope(:list_user_articles, current_user, %{user_id: user_id})
    |> order_by(desc: :inserted_at)
    |> preload([:user, :comments, :tags])
    |> with_stats(current_user)
    |> Repo.all()
  end

  @doc """
  Lists articles from users that the current user follows.
  Uses policy scopes to filter based on following relationships.

  ## Options

    * `:after` - cursor for pagination (article ID)
    * `:limit` - number of articles to return (default: 10)

  """
  def list_following_articles(user, opts \\ []) do
    after_cursor = opts[:after]
    limit = opts[:limit] || 10

    query =
      Article
      |> Policies.scope(:list_following_articles, user)
      |> order_by(desc: :inserted_at, desc: :id)
      |> limit(^limit)
      |> preload([:user, :tags, :comments])

    query =
      if after_cursor do
        # Get the cursor article to compare timestamps
        cursor_article = Repo.get!(Article, after_cursor)

        from a in query,
          where:
            a.inserted_at < ^cursor_article.inserted_at or
              (a.inserted_at == ^cursor_article.inserted_at and a.id < ^cursor_article.id)
      else
        query
      end

    query
    |> with_stats(user)
    |> Repo.all()
  end

  @doc """
  Lists articles by tag.

  ## Options

    * `:after` - cursor for pagination (article ID)
    * `:limit` - number of articles to return (default: 10)
  """
  def list_articles_by_tag(tag_name, user, opts \\ []) do
    after_cursor = opts[:after]
    limit = opts[:limit] || 10

    query =
      from a in Article,
        join: t in assoc(a, :tags),
        where: t.name == ^tag_name,
        distinct: true,
        order_by: [desc: a.inserted_at, desc: a.id],
        limit: ^limit,
        preload: [:user, :tags, :comments]

    query =
      if after_cursor do
        # Get the cursor article to compare timestamps
        cursor_article = Repo.get!(Article, after_cursor)

        from a in query,
          where:
            a.inserted_at < ^cursor_article.inserted_at or
              (a.inserted_at == ^cursor_article.inserted_at and a.id < ^cursor_article.id)
      else
        query
      end

    query
    |> Policies.scope(:list_articles, user)
    |> with_stats(user)
    |> Repo.all()
  end

  @doc """
  Lists articles from followed users filtered by tag.

  ## Options

    * `:after` - cursor for pagination (article ID)
    * `:limit` - number of articles to return (default: 10)
  """
  def list_following_articles_by_tag(tag_name, user, opts \\ []) do
    after_cursor = opts[:after]
    limit = opts[:limit] || 10

    query =
      Article
      |> Policies.scope(:list_following_articles, user)
      |> join(:inner, [a, ...], t in assoc(a, :tags))
      |> where([a, _uf, t], t.name == ^tag_name)
      |> distinct(true)
      |> order_by([a], desc: a.inserted_at, desc: a.id)
      |> limit(^limit)
      |> preload([:user, :tags, :comments])

    query =
      if after_cursor do
        # Get the cursor article to compare timestamps
        cursor_article = Repo.get!(Article, after_cursor)

        from a in query,
          where:
            a.inserted_at < ^cursor_article.inserted_at or
              (a.inserted_at == ^cursor_article.inserted_at and a.id < ^cursor_article.id)
      else
        query
      end

    query
    |> with_stats(user)
    |> Repo.all()
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
    |> Repo.preload([:user, :tags])
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
    |> Repo.preload([:user, :tags])
  end

  @doc """
  Gets a single article by slug with stats for the given user.
  """
  def get_article_by_slug_with_stats!(slug, user) do
    Article
    |> where(slug: ^slug)
    |> preload([:user, :tags])
    |> with_stats(user)
    |> Repo.one!()
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

  @doc """
  Associates tags with an article.
  Tags should be provided as a list of tag names.
  """
  def update_article_tags(%Article{} = article, tag_names) when is_list(tag_names) do
    # Delete existing tags
    from(at in "article_tags", where: at.article_id == ^article.id)
    |> Repo.delete_all()

    # Insert new tags
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    tag_entries =
      Enum.map(tag_names, fn name ->
        case get_or_create_tag(name) do
          {:ok, tag} ->
            %{
              article_id: article.id,
              tag_id: tag.id,
              inserted_at: now
            }

          _ ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    if tag_entries != [] do
      Repo.insert_all("article_tags", tag_entries)
    end

    {:ok, Repo.preload(article, :tags, force: true)}
  end

  # =====================================
  # Comment Functions
  # =====================================

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

  # =====================================
  # Tag Functions
  # =====================================

  @doc """
  Lists all tags.
  """
  def list_tags do
    Tag
    |> order_by(:name)
    |> Repo.all()
  end

  @doc """
  Gets or creates a tag by name.
  """
  def get_or_create_tag(name) do
    name = String.trim(name)

    case Repo.get_by(Tag, name: name) do
      nil ->
        %Tag{}
        |> Tag.changeset(%{name: name})
        |> Repo.insert()

      tag ->
        {:ok, tag}
    end
  end

  # =====================================
  # ArticleFavorite Functions
  # =====================================

  @doc """
  Favorites an article for a user.
  """
  def favorite_article(%User{id: user_id}, %Article{id: article_id}) do
    %ArticleFavorite{}
    |> ArticleFavorite.changeset(%{user_id: user_id, article_id: article_id})
    |> Repo.insert()
  end

  @doc """
  Unfavorites an article for a user.
  """
  def unfavorite_article(%User{id: user_id}, %Article{id: article_id}) do
    %ArticleFavorite{user_id: user_id, article_id: article_id}
    |> Repo.delete()
  end

  # =====================================
  # Helper Functions
  # =====================================

  @doc """
  Efficiently loads articles with favorites count and favorited status for a user.
  Uses a single query with lateral joins to avoid N+1 problems.
  """
  def with_stats(query, user) do
    favorites_count_query =
      from f in ArticleFavorite,
        where: f.article_id == parent_as(:article).id,
        select: %{count: count(f.article_id)}

    user_favorited_query =
      case user do
        %User{id: user_id} ->
          from f in ArticleFavorite,
            where: f.article_id == parent_as(:article).id and f.user_id == ^user_id,
            select: %{favorited: count(f.article_id) > 0}

        nil ->
          from f in ArticleFavorite,
            where: false,
            select: %{favorited: false}
      end

    from a in query,
      as: :article,
      left_lateral_join: fc in subquery(favorites_count_query),
      on: true,
      left_lateral_join: uf in subquery(user_favorited_query),
      on: true,
      select_merge: %{
        favorites_count: coalesce(fc.count, 0),
        favorited: coalesce(uf.favorited, false)
      }
  end
end
