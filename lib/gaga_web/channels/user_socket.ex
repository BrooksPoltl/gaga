defmodule GagaWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "tables:*", GagaWeb.TableChannel

  @impl true
  def connect(%{"token" => token}, socket) do
    case Phoenix.Token.verify(socket, System.get_env("TOKEN_SECRET"), token) do
      {:ok, user_id} ->
        {:ok, assign(socket, :user_id, user_id)}

      {:error, _error} ->
        :error
    end
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     GagaWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  @impl true
  def id(_socket), do: nil
end
