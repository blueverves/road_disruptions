defmodule RoadDisruptions.DisruptionsStreamHandler do
  use GenEvent
  require Logger
  alias RoadDisruptions.DisruptionsStreamParser

  def init(args) do
    {:ok, args}
  end

  def handle_event(%{start_stream: value}, _stream) do
    Logger.debug "DisruptionsStreamHandler: start stream"
    stream = DisruptionsStreamParser.run
    |> Stream.dedup_by(fn(d) -> d.id end)
    |> Stream.map(&(&1))
    {:ok, stream}
  end

  def handle_event(%{filter_by_severity: value}, stream) do
    Logger.debug "DisruptionsStreamHandler: filter by severity"
    filtered_stream = stream
    |> Stream.filter_map(fn(d) -> d.severity == value end, &(&1))
    {:ok, filtered_stream}
  end

  def handle_event(%{filter_by_status: value}, stream) do
    Logger.debug "DisruptionsStreamHandler: filter by status"
    filtered_stream = stream
    |> Stream.filter_map(fn(d) -> d.status == value end, &(&1))
    {:ok, filtered_stream}
  end

  def handle_call(:disruptions, stream) do
    Logger.debug "DisruptionsStreamHandler: handle call disruptions"
    {:ok, stream, []}
  end

end
