defmodule TableChannelTest do
  # use GagaWeb.ChannelCase
  # # using do
  # #   quote do
  # #     doctest GagaWeb.TableChannel
  # #     # Import conveniences for testing with channels
  # #     import Phoenix.ChannelTest

  # #     # The default endpoint for testing
  # #     @endpoint GagaWeb.Endpoint
  # #     import TestHelper

  # #
  # #   end
  # # end
  # import(Gaga.Factory)

  # setup do
  #   user1 = insert(:user)
  #   user2 = insert(:user)
  #   user3 = insert(:user)

  #   room1 = insert(:room, user: user1)
  #   insert(:room_user, user_id: user1.id, room_id: room1.id)
  #   insert(:room_user, user_id: user2.id, room_id: room1.id)

  #   GagaWeb.UserSocket
  #   |> socket("user_id", %{user_id: user1.id})
  #   |> subscribe_and_join(GagaWeb.TableChannel, "tables:#{room1.id}")

  #   %{socket: socket}
  # end

  # test "handles1 person is passed in", %{socket: socket} do
  #   # insert(:room_user, user_id: user3.id, room_id: room1.id)
  #   IO.inspect(socket)
  #   # ref = push(socket, "get_table", %{})
  #   IO.inspect(Gaga.Poker.list_rooms())
  #   assert true == false
  # end
end
