defmodule Gaga.Repo do
  use Ecto.Repo,
    otp_app: :gaga,
    adapter: Ecto.Adapters.Postgres
end
