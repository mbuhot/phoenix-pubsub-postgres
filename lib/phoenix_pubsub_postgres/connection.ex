defmodule PhoenixPubSubPostgres.Connection do
  use GenServer

  @moduledoc """
  The connection pool for the `PhoenixPubSubPostgres` adapter
  See `PhoenixPubSubPostgres` for configuration details.
  """

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init([opts]) do
    Process.flag(:trap_exit, true)
    {:ok, {:disconnected, opts}}
  end

  def handle_call(:conn, _, {:disconnected, opts}) do
    case Postgrex.Connection.start_link(opts) do
      {:ok, pid}    -> {:reply, {:ok, pid}, {pid, opts}}
      {:error, err} -> {:reply, {:error, err}, {:disconnected, opts}}
    end
  end

  def handle_call(:conn, _, {pid, opts}) do
    {:reply, {:ok, pid}, {pid, opts}}
  end

  def handle_info({:EXIT, pid, _}, {pid, opts}) do
    {:noreply, {:disconnected, opts}}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  def terminate(_reason, {:disconnected, _}), do: :ok
  def terminate(_reason, {pid, _}) do
    try do
      Postgrex.Connection.stop(conn)
    catch
      :exit, {:noproc, _} -> :ok
    end
    :ok
  end
end
