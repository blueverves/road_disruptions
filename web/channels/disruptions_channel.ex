defmodule RoadDisruptions.DisruptionsChannel do
  use RoadDisruptions.Web, :channel
  require Logger

  @delay 5000
  @new_items_no 10

  def join("disruptions:lobby", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("start_stream", payload, socket) do
    Logger.debug "DisruptionsChannel: start stream"

    # start a new event manager
    {:ok, manager} = GenEvent.start_link([])
    # attach an event handler to the event manager
    GenEvent.add_handler(manager, DisruptionsFeedHandler, [])
    # trigger the news feed
    GenEvent.sync_notify(manager, :start_stream)
    # get the disruptions stream
    stream = GenEvent.call(manager, DisruptionsFeedHandler, :disruptions)
    |> Stream.chunk(@new_items_no)

    for disruptions <- stream do
      disruptions
      |> Stream.take(1)
      |> Enum.to_list
      |> List.flatten

      Logger.debug "DisruptionsChannel: push disruptions"
      # send new marker to the client
      push socket, "new_markers", %{markers: markers(disruptions)}
      # send new feed entry to the client
      push socket, "new_disruptions", %{disruptions: disruptions}
      Process.sleep(@delay)
    end

    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (disruptions:lobby).
  def handle_in("notify", payload, socket) do
    broadcast socket, "notify", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  defp markers(disruptions) do
    Enum.map(disruptions, fn disruption ->
      %{
          type: "Feature",
            geometry: %{
            type: "Point",
            coordinates: disruption.cause_area.display_point
          },
          properties: %{
            id: disruption.id,
            description: disruption.location,
            comments: disruption.comments,
            "marker-symbol": "roadblock-15"
          }
      }
    end)
  end
end
