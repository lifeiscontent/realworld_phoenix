defmodule Realworld.Policies do
  @moduledoc """
  Central authorization policies for the application.
  This module defines authorization rules that can be used throughout the application.
  """

  alias Realworld.Accounts.User
  alias Realworld.Blog.Article
  alias Realworld.Blog.Comment

  @doc """
  Authorizes an action for a user on a resource.

  Returns :ok if authorized, {:error, :unauthorized} if not.
  """
  def authorize(action, user, resource \\ nil)

  # Admin users can do anything
  def authorize(_action, %User{role: "admin"}, _resource), do: :ok

  # User profile actions
  def authorize(:update_profile, %User{id: user_id}, %User{id: user_id}), do: :ok
  def authorize(:delete_account, %User{id: user_id}, %User{id: user_id}), do: :ok

  # Article actions
  def authorize(:create_article, %User{}, nil), do: :ok

  def authorize(:create_article, %User{id: user_id}, %{"user_id" => param_user_id}) do
    if to_string(user_id) == param_user_id do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  def authorize(:list_articles, _user, nil), do: :ok
  def authorize(:view_article, _user, %Article{status: "published"}), do: :ok
  def authorize(:view_article, %User{id: user_id}, %Article{user_id: user_id}), do: :ok
  def authorize(:update_article, %User{id: user_id}, %Article{user_id: user_id}), do: :ok
  def authorize(:delete_article, %User{id: user_id}, %Article{user_id: user_id}), do: :ok

  # Comment actions
  def authorize(:create_comment, %User{}, %Article{status: "published"}), do: :ok
  def authorize(:create_comment, %User{id: user_id}, %Article{user_id: user_id}), do: :ok

  def authorize(:create_comment, %User{id: user_id}, %{
        "user_id" => param_user_id,
        "article_id" => _
      }) do
    if to_string(user_id) == param_user_id do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  def authorize(:view_comments, _user, %Article{status: "published"}), do: :ok
  def authorize(:view_comments, %User{id: user_id}, %Article{user_id: user_id}), do: :ok
  def authorize(:update_comment, %User{id: user_id}, %Comment{user_id: user_id}), do: :ok
  def authorize(:delete_comment, %User{id: user_id}, %Comment{user_id: user_id}), do: :ok

  # Favorite actions
  def authorize(:favorite_article, %User{}, %Article{status: "published"}), do: :ok
  def authorize(:favorite_article, %User{id: user_id}, %Article{user_id: user_id}), do: :ok
  def authorize(:unfavorite_article, %User{}, %Article{}), do: :ok

  # Following actions
  def authorize(:follow_user, %User{id: follower_id}, %User{id: following_id})
      when follower_id != following_id,
      do: :ok

  def authorize(:unfollow_user, %User{}, %User{}), do: :ok

  # Default deny
  def authorize(_action, _user, _resource), do: {:error, :unauthorized}

  @doc """
  Checks if an action is permitted for a user on a resource.

  Can accept a single action or a list of actions. For a list of actions,
  returns true if ANY of the actions are permitted.

  ## Examples

      iex> permit?(:update_article, user, article)
      true
      
      iex> permit?([:update_article, :delete_article], user, article)
      true

  Returns true if authorized, false otherwise.
  """
  def permit?(action, user, resource \\ nil)

  def permit?(actions, user, resource) when is_list(actions) do
    Enum.any?(actions, fn action -> permit?(action, user, resource) end)
  end

  def permit?(action, user, resource) do
    case authorize(action, user, resource) do
      :ok -> true
      _ -> false
    end
  end

  @doc """
  Checks if a user has a specific role.
  """
  def has_role?(%User{role: role}, role), do: true
  def has_role?(_user, _role), do: false

  @doc """
  Checks if a user is an admin.
  """
  def admin?(%User{role: "admin"}), do: true
  def admin?(_user), do: false

  @doc """
  Checks if a user owns a resource.
  """
  def owns?(%User{id: user_id}, %{user_id: user_id}), do: true
  def owns?(%User{id: user_id}, %{owner_id: user_id}), do: true
  def owns?(_user, _resource), do: false

  @doc """
  Scopes a query to only include resources visible to the given user.
  Following Bodyguard's pattern for query-level authorization.

  ## Examples

      iex> Article |> Policies.scope(:list_articles, user) |> Repo.all()
      [%Article{}, ...]
      
  """
  def scope(query, action, user, params \\ %{})

  # Article scopes
  def scope(query, :list_articles, %User{role: "admin"}, _params) do
    # Admins can see all articles
    query
  end

  def scope(query, :list_articles, %User{id: user_id}, _params) do
    # Authenticated users can see their own articles and published articles
    import Ecto.Query

    from a in query,
      where: a.user_id == ^user_id or a.status == "published"
  end

  def scope(query, :list_articles, nil, _params) do
    # Unauthenticated users can only see published articles
    import Ecto.Query
    from a in query, where: a.status == "published"
  end

  # User articles scope - all articles for the author, only published for others
  def scope(query, :list_user_articles, %User{id: current_user_id}, %{user_id: profile_user_id}) do
    import Ecto.Query

    if current_user_id == profile_user_id do
      # User viewing their own profile sees all their articles
      from a in query, where: a.user_id == ^profile_user_id
    else
      # Other users only see published articles
      from a in query, where: a.user_id == ^profile_user_id and a.status == "published"
    end
  end

  def scope(query, :list_user_articles, nil, %{user_id: profile_user_id}) do
    # Unauthenticated users only see published articles
    import Ecto.Query
    from a in query, where: a.user_id == ^profile_user_id and a.status == "published"
  end

  # Following articles scope - articles from followed users
  def scope(query, :list_following_articles, %User{id: user_id}, _params) do
    import Ecto.Query

    from a in query,
      join: uf in Realworld.Accounts.UserFollow,
      on: uf.following_id == a.user_id and uf.follower_id == ^user_id,
      where: a.status == "published"
  end

  def scope(query, :list_following_articles, nil, _params) do
    # Unauthenticated users see no following articles
    import Ecto.Query
    from q in query, where: false
  end

  # Default scope (deny all)
  def scope(query, _action, _user, _params) do
    import Ecto.Query
    from q in query, where: false
  end
end
