defmodule Realworld.Accounts.UserFollow do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "user_follows" do
    belongs_to :follower, Realworld.Accounts.User
    belongs_to :following, Realworld.Accounts.User

    timestamps(updated_at: false, type: :utc_datetime)
  end

  @doc false
  def changeset(user_follow, attrs) do
    user_follow
    |> cast(attrs, [:follower_id, :following_id])
    |> validate_required([:follower_id, :following_id])
    |> foreign_key_constraint(:follower_id)
    |> foreign_key_constraint(:following_id)
    |> unique_constraint([:follower_id, :following_id])
    |> check_constraint(:follower_id, name: :cannot_follow_self,
        message: "cannot follow yourself")
  end
end