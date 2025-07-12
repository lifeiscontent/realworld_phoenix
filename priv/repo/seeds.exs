# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Realworld.Repo.insert!(%Realworld.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query
alias Realworld.Repo
alias Realworld.Accounts
alias Realworld.Blog

# Create some test users
users =
  for i <- 1..10 do
    {:ok, user} =
      Accounts.register_user(%{
        email: "user#{i}@example.com",
        username: "user#{i}",
        password: "password123456",
        bio: "I'm test user number #{i}",
        time_zone: "America/New_York"
      })

    user
  end

# Create admin user
{:ok, admin} =
  Accounts.register_user(%{
    email: "admin@example.com",
    username: "admin",
    password: "password123456",
    bio: "I'm the admin",
    time_zone: "America/New_York"
  })

# Update admin role
admin |> Ecto.Changeset.change(role: "admin") |> Repo.update!()

# Create some tags
tags = [
  "programming",
  "elixir",
  "phoenix",
  "liveview",
  "web",
  "tutorial",
  "beginner",
  "advanced",
  "tips",
  "news"
]

# Create many articles for each user to test pagination
Enum.each(users, fn user ->
  # Each user creates 15-25 articles
  num_articles = :rand.uniform(11) + 14

  for i <- 1..num_articles do
    # Random number of tags per article (1-3)
    article_tags = Enum.take_random(tags, :rand.uniform(3))

    {:ok, article} =
      Blog.create_article(%{
        title: "Article #{i} by #{user.username}",
        body: """
        This is article number #{i} written by #{user.username}.

        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. 
        Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

        This article covers topics like #{Enum.join(article_tags, ", ")}.
        """,
        status: if(:rand.uniform(100) > 10, do: "published", else: "draft"),
        user_id: user.id
      })

    # Add tags to the article
    if article.status == "published" do
      Blog.update_article_tags(article, article_tags)
    end

    # Sleep briefly to ensure different timestamps
    :timer.sleep(10)
  end
end)

# Create following relationships
# Each user follows 3-5 other users randomly
Enum.each(users, fn user ->
  following_count = :rand.uniform(3) + 2
  users_to_follow = (users -- [user]) |> Enum.take_random(following_count)

  Enum.each(users_to_follow, fn followed_user ->
    Accounts.follow_user(user, followed_user)
  end)
end)

# Admin follows everyone
Enum.each(users, fn user ->
  Accounts.follow_user(admin, user)
end)

# Add some favorites to articles
published_articles = Repo.all(from a in Blog.Article, where: a.status == "published", limit: 100)

Enum.each(users ++ [admin], fn user ->
  # Each user favorites 5-15 random articles
  favorites_count = :rand.uniform(11) + 4
  articles_to_favorite = Enum.take_random(published_articles, favorites_count)

  Enum.each(articles_to_favorite, fn article ->
    Blog.favorite_article(user, article)
  end)
end)

# Add some comments to articles  
Enum.each(Enum.take_random(published_articles, 50), fn article ->
  # Add 1-5 comments per article
  num_comments = :rand.uniform(5)
  commenting_users = Enum.take_random(users ++ [admin], num_comments)

  Enum.each(commenting_users, fn user ->
    Blog.create_comment(%{
      content: "This is a great article! Comment by #{user.username}.",
      user_id: user.id,
      article_id: article.id
    })
  end)
end)

IO.puts("Seeding completed!")
IO.puts("Created #{length(users) + 1} users (including admin)")
IO.puts("Created #{Repo.aggregate(Blog.Article, :count)} articles")
IO.puts("Created #{Repo.aggregate(Blog.Comment, :count)} comments")
