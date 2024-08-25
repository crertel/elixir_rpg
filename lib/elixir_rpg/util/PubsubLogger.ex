defmodule ElixirRpg.PubSubLoggerBackend do
  @moduledoc ~S"""
  A logger backend that logs messages by printing them to the console.

  Adapted shamelessly from the console logger.

  ## Options

    * `:exchange` - the exchange to publish to

    * `:topic` - the topic to publish to

    * `:level` - the level to be logged by this backend.
      Note that messages are filtered by the general
      `:level` configuration for the `:logger` application first.

    * `:format` - the format message used to print logs.
      Defaults to: `"\n$time $metadata[$level] $message\n"`.
      It may also be a `{module, function}` tuple that is invoked
      with the log level, the message, the current timestamp and
      the metadata and must return `t:IO.chardata/0`. See
      `Logger.Formatter`.

    * `:metadata` - the metadata to be printed by `$metadata`.
      Defaults to an empty list (no metadata).
      Setting `:metadata` to `:all` prints all metadata. See
      the "Metadata" section in the `Logger` documentation for
      more information.

  Here is an example of how to configure this backend in a
  `config/config.exs` file:

      config :logger, PubSubLoggerBackend,
        format: "\n$time $metadata[$level] $message\n",
        metadata: [:user_id]

  """

  @behaviour :gen_event

  defstruct topic: nil,
            exchange: nil,
            format: nil,
            level: nil,
            metadata: nil

  @impl true
  def init(atom) when is_atom(atom) do
    config = read_env()
    {:ok, init(config, %__MODULE__{})}
  end

  def init({__MODULE__, opts}) when is_list(opts) do
    config = configure_merge(read_env(), opts)
    {:ok, init(config, %__MODULE__{})}
  end

  @impl true
  def handle_call({:configure, options}, state) do
    {:ok, :ok, configure(options, state)}
  end

  @impl true
  def handle_event(
        {level, _gl, {Logger, msg, ts, md}},
        %{format: format, metadata: keys, level: log_level, topic: topic, exchange: exchange} =
          state
      ) do
    {:erl_level, level} = List.keyfind(md, :erl_level, 0, {:erl_level, level})

    if meet_level?(level, log_level) do
      formatted_msg = Logger.Formatter.format(format, level, msg, ts, take_metadata(md, keys))

      try do
        Phoenix.PubSub.broadcast(
          exchange,
          topic,
          {Logger, level, formatted_msg}
        )
      rescue
        _ -> :ok
      end
    end

    {:ok, state}
  end

  def handle_event(_, state), do: {:ok, state}

  @impl true
  def handle_info(_, state), do: {:ok, state}

  @impl true
  def code_change(_old_vsn, state, _extra), do: {:ok, state}

  @impl true
  def terminate(_reason, _state), do: :ok

  ## Helpers

  defp meet_level?(_lvl, nil), do: true

  defp meet_level?(lvl, min), do: Logger.compare_levels(lvl, min) != :lt

  defp configure(options, state) do
    config = configure_merge(read_env(), options)
    Application.put_env(:logger, __MODULE__, config)
    init(config, state)
  end

  defp init(config, state),
    do: %{
      state
      | format: Logger.Formatter.compile(Keyword.get(config, :format)),
        topic: Keyword.get(config, :topic, "util:log:messages"),
        exchange: Keyword.get(config, :exchange),
        metadata: Keyword.get(config, :metadata, []) |> configure_metadata(),
        level: Keyword.get(config, :level)
    }

  defp configure_metadata(:all), do: :all
  defp configure_metadata(metadata), do: Enum.reverse(metadata)

  defp configure_merge(env, options) do
    Keyword.merge(env, options, fn
      :colors, v1, v2 -> Keyword.merge(v1, v2)
      _, _v1, v2 -> v2
    end)
  end

  defp take_metadata(metadata, :all), do: metadata

  defp take_metadata(metadata, keys) do
    Enum.reduce(keys, [], fn key, acc ->
      case Keyword.fetch(metadata, key) do
        {:ok, val} -> [{key, val} | acc]
        :error -> acc
      end
    end)
  end

  defp read_env,
    do: Application.get_env(:logger, __MODULE__, Application.get_env(:logger, :console, []))
end
