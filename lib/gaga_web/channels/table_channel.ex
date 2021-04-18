defmodule GagaWeb.TableChannel do
  use GagaWeb, :channel
  alias Gaga.Poker

  def join("tables:" <> room_id, _params, socket) do
    users = Poker.get_users_at_table(room_id)
    IO.inspect(users)
    {:ok, users, socket}
  end

  def handle_in(_name, _body, socket) do
    IO.inspect(socket)
    {:reply, :ok, socket}
  end
end
