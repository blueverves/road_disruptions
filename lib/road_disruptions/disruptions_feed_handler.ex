defmodule DisruptionsFeedHandler do
  use GenEvent
  require Logger

  def init(args) do
    {:ok, args}
  end

  def handle_event(events, stream) do
    Logger.debug "DisruptionsFeedHandler: handle event"

    {:ok, disruptions} = process_events(Map.keys(events), events, stream)
    Logger.debug "DisruptionsFeedHandler: return disruptions"
    {:ok, disruptions}
  end

  def handle_call(:disruptions, stream) do
    Logger.debug "DisruptionsFeedHandler: handle call disruptions"
    {:ok, stream, []}
  end

  defp process_events([head | tail], events, stream) do
    process_events(tail,
                   events,
                   process_event(Map.put(%{}, head, events[head]), stream)
                  )
  end

  defp process_events([], _, stream) do
    {:ok, stream}
  end

  defp process_event(%{start_stream: _}, stream) do
    Logger.debug "DisruptionsFeedHandler: start feed"
    StreamingXmlParser.run
    |> Stream.dedup_by(fn(d) -> d.id end)
    |> Stream.map(&(&1))
  end

  defp process_event(%{filter_by_severity: value}, stream) do
    Logger.debug "DisruptionsFeedHandler: filter by severity"
    stream
    |> Stream.filter_map(fn(d) -> d.severity == value end, &(&1))
  end

  defp process_event(%{filter_by_status: value}, stream) do
    Logger.debug "DisruptionsFeedHandler: filter by status"
    stream
    |> Stream.filter_map(fn(d) -> d.status == value end, &(&1))
  end

end
