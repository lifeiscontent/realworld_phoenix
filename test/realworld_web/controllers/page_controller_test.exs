defmodule RealworldWeb.PageControllerTest do
  use RealworldWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/articles"
  end
end
