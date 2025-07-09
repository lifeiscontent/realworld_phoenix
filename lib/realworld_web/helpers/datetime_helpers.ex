defmodule RealworldWeb.DateTimeHelpers do
  @moduledoc """
  Helper functions for formatting dates and times in the user's timezone.
  """

  @doc """
  Formats a UTC datetime to the user's local timezone.
  """
  def format_datetime(datetime, timezone) do
    case DateTime.shift_zone(datetime, timezone) do
      {:ok, local_datetime} ->
        Calendar.strftime(local_datetime, "%B %d, %Y at %I:%M %p")

      {:error, _} ->
        # Fallback to UTC if timezone conversion fails
        Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p UTC")
    end
  end
end
