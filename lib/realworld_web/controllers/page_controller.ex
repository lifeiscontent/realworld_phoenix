defmodule RealworldWeb.PageController do
  use RealworldWeb, :controller

  def home(conn, _params) do
    # Redirect to articles as the home page
    redirect(conn, to: ~p"/articles")
  end
end
