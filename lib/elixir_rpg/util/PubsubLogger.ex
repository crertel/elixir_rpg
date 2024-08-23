defmodule ElixirRpg.PubSubLoggerBackend do
  @behaviour :gen_event

  def init(__MODULE__) do
    {:ok, %{}}
  end

  def handle_call({:configure, _options}, state) do
    {:ok, :ok, state}
  end

  def handle_event({level, _gl, {Logger, msg, timestamp, metadata}}, state) do
    message = format_message(level, msg, timestamp, metadata)
    Phoenix.PubSub.broadcast(ElixirRpg.PubSub, "util:log:messages", {:log, message, format_timestamp(timestamp)})
    {:ok, state}
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  defp format_message(level, msg, timestamp, _metadata) do
    "[#{format_timestamp(timestamp)}] [#{level}] #{msg}"
  end

  defp format_timestamp( {date, {hour, minute, second, millisecond}} ), do: :io_lib.format(
    "~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B.~3..0B",
    Tuple.to_list(date) ++ [hour, minute, second, millisecond]
  ) |> IO.iodata_to_binary()
end
