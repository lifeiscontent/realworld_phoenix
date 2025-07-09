defmodule RealworldWeb.UserSettingsLive.Edit do
  use RealworldWeb, :live_view

  alias Realworld.Accounts

  on_mount RealworldWeb.AuthLive
  on_mount {RealworldWeb.AuthLive, :require_authenticated_user}

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(:page_title, "Settings")
     |> assign(:uploaded_files, [])
     |> allow_upload(:avatar, accept: ~w(.jpg .jpeg .png), max_entries: 1)
     |> assign(:profile_form, to_form(Accounts.change_user_profile(user)))
     |> assign(:email_form, to_form(Accounts.change_user_email(user)))
     |> assign(:password_form, to_form(Accounts.change_user_password(user)))}
  end

  @impl true
  def handle_event("validate_profile", %{"user" => user_params}, socket) do
    changeset =
      socket.assigns.current_user
      |> Accounts.change_user_profile(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :profile_form, to_form(changeset))}
  end

  @impl true
  def handle_event("save_profile", %{"user" => user_params}, socket) do
    user = socket.assigns.current_user

    user_params = 
      case consume_uploaded_entries(socket, :avatar, fn %{path: path}, entry ->
        file_name = "#{user.id}-#{:erlang.phash2(DateTime.utc_now())}#{Path.extname(entry.client_name)}"
        dest = Path.join([:code.priv_dir(:realworld), "static", "uploads", "avatars", file_name])
        File.mkdir_p!(Path.dirname(dest))
        File.cp!(path, dest)
        {:ok, "/uploads/avatars/#{file_name}"}
      end) do
        [image_path] -> Map.put(user_params, "image", image_path)
        [] -> user_params
      end

    case Accounts.update_user_profile(user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:current_user, user)
         |> assign(:profile_form, to_form(Accounts.change_user_profile(user)))
         |> put_flash(:info, "Profile updated successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, :profile_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  @impl true
  def handle_event("validate_email", %{"current_password" => _password, "user" => user_params}, socket) do
    changeset =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :email_form, to_form(changeset))}
  end

  @impl true
  def handle_event("save_email", %{"current_password" => password, "user" => user_params}, socket) do
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        {:noreply,
         socket
         |> put_flash(:info, "A link to confirm your email change has been sent to the new address.")
         |> assign(:email_form, to_form(Accounts.change_user_email(user)))}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("validate_password", %{"current_password" => _password, "user" => user_params}, socket) do
    changeset =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :password_form, to_form(changeset))}
  end

  @impl true
  def handle_event("save_password", %{"current_password" => password, "user" => user_params}, socket) do
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:password_form, to_form(Accounts.change_user_password(user)))
         |> put_flash(:info, "Password updated successfully.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :password_form, to_form(changeset))}
    end
  end
end