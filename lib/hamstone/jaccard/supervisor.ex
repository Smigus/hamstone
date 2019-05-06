defmodule Hamstone.Jaccard.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      Hamstone.Jaccard,
      {DynamicSupervisor, name: Hamstone.Jaccard.TPSupervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end