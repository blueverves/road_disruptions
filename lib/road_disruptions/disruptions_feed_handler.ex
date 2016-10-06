defmodule DisruptionsFeedHandler do
  use GenEvent
  require Logger

  @new_items_no 10

  def init(args) do
    {:ok, args}
  end

  def handle_event(event, stream) do
    Logger.debug "DisruptionsFeedHandler: handle event"
    {:ok, disruptions} = process_event(event, stream)
    Logger.debug "DisruptionsFeedHandler: return disruptions"
    {:ok, disruptions}
  end

  def handle_call(:disruptions, stream) do
    Logger.debug "DisruptionsFeedHandler: handle call disruptions"
    {:ok, stream, stream}
  end

  defp process_event(:start_stream, stream) do
    Logger.debug "DisruptionsFeedHandler: start feed"
    disruptions = StreamingXmlParser.run
    |> Stream.take(@new_items_no)
    |> Stream.map(&(&1))
    |> Enum.to_list
    process_event(:order_by_severity, disruptions)
  end

  defp process_event(:next_dataset, stream) do
    Logger.debug "DisruptionsFeedHandler: next dataset"
    disruptions = stream
    |> Stream.take(@new_items_no)
    |> Stream.map(&(&1))
    |> Enum.to_list
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
