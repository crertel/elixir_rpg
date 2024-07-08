defmodule ElixirRpg.Repo do
  use Ecto.Repo,
    otp_app: :elixir_rpg,
    adapter: Ecto.Adapters.Postgres
end
