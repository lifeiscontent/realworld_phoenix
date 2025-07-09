defmodule RealworldWeb.TimeZoneLive do
  @moduledoc """
  LiveView helpers for time zone handling.
  
  Usage in LiveView modules:
  
      use RealworldWeb, :live_view
      on_mount RealworldWeb.TimeZoneLive
  """
  import Phoenix.LiveView
  import Phoenix.Component
  
  def on_mount(:default, _params, _session, socket) do
    # Assign time_zone based on user preference or browser timezone
    time_zone = 
      case socket.assigns[:current_user] do
        %{time_zone: user_tz} when is_binary(user_tz) -> user_tz
        _ -> get_connect_params(socket)["timezone"] || "UTC"
      end
    
    {:cont, assign(socket, :time_zone, time_zone)}
  end
end