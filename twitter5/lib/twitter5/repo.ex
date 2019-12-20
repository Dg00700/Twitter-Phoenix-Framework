defmodule Twitter5.Repo do
  use Ecto.Repo,
    otp_app: :twitter5,
    adapter: Ecto.Adapters.Postgres
end
