defmodule DisruptionsFeedHandler do
  use GenEvent
  require Logger

  def init(args) do
    {:ok, args}
  end

  def handle_event(%{start_stream: value}, _stream) do
    Logger.debug "DisruptionsFeedHandler: start stream"
    stream = StreamingXmlParser.run
    |> Stream.dedup_by(fn(d) -> d.id end)
    |> Stream.map(&(&1))
    {:ok, stream}
  end

  def handle_event(%{filter_by_severity: value}, stream) do
    Logger.debug "DisruptionsFeedHandler: filter by severity"
    filtered_stream = stream
    |> Stream.filter_map(fn(d) -> d.severity == value end, &(&1))
    {:ok, filtered_stream}
  end

  def handle_event(%{filter_by_status: value}, stream) do
    Logger.debug "DisruptionsFeedHandler: filter by status"
    filtered_stream = stream
    |> Stream.filter_map(fn(d) -> d.status == value end, &(&1))
    {:ok, filtered_stream}
  end

  def handle_call(:disruptions, stream) do
    Logger.debug "DisruptionsFeedHandler: handle call disruptions"
    {:ok, stream, []}
  end

end
