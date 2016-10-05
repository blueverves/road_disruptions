defmodule DisruptionsFeedHandler do
  use GenEvent
  require Logger

  @delay 100

  def init(args) do
    {:ok, args}
  end

  def handle_event(event, stream) do
    Logger.debug " DisruptionsFeedHandler: handle event"
    {:ok, disruptions} = process_event(event, stream)
    Logger.debug " DisruptionsFeedHandler: return disruptions"
    IO.inspect disruptions
    {:ok, disruptions}
  end

  def handle_call(:disruptions, stream) do
    Logger.debug " DisruptionsFeedHandler: handle call disruptions"

    {:ok, stream, []}
  end

  defp process_event(:start_feed, stream) do
    Logger.debug "DisruptionsFeedHandler: start feed"
    disruptions = StreamingXmlParser.run |> Stream.map(&(&1))
    process_event(:order_by_severity, disruptions)
  end

  defp process_event(:order_by_severity, stream) do
    Logger.debug "DisruptionsFeedHandler: order by severity"
    # TODO: implement ordering
    process_event(:order_by_status, stream)
  end

  defp process_event(:order_by_status, stream) do
    Logger.debug "DisruptionsFeedHandler: order by status"
    # TODO: implement ordering
    {:ok, stream}
  end
end
