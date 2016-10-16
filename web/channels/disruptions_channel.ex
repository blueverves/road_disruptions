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
    # store manager in socket
    socket = assign(socket, :manager, manager)
    # trigger the news feed
    GenEvent.sync_notify(manager, %{start_stream: []})

    {:reply, {:ok, payload}, socket}
  end

  def handle_in("filter_by_severity", payload, socket) do
    Logger.debug "DisruptionsChannel: filter by severity"
    filter_settings = keys_to_atom(payload)

    # get stored GenEvent manager
    manager = get_in(socket.assigns, [:manager])
    # filter stream by settings
    GenEvent.sync_notify(manager, filter_settings)

    {:reply, {:ok, payload}, socket}
  end

  def handle_in("filter_by_status", payload, socket) do
    Logger.debug "DisruptionsChannel: filter by status"
    filter_settings = keys_to_atom(payload)

    # get stored GenEvent manager
    manager = get_in(socket.assigns, [:manager])
    # filter stream by settings
    GenEvent.sync_notify(manager, filter_settings)

    {:reply, {:ok, payload}, socket}
  end

  def handle_in("stream_disruptions", payload, socket) do
    Logger.debug "DisruptionsChannel: stream disruptions"
    # get stored GenEvent manager
    manager = get_in(socket.assigns, [:manager])
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

  defp keys_to_atom(map) do
    map
    |> Enum.reduce(%{}, fn ({key, val}, acc) -> Map.put(acc, String.to_atom(key), val) end)
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
            location: disruption.location,
            comments: disruption.comments,
            "marker-symbol": marker_symbol(disruption.severity)
          }
      }
    end)
  end

  defp marker_symbol(severity) do
    case severity do
      "Severe" -> "roadblock-15"
      "Serious" -> "roadblock-11"
      "Moderate" -> "car-15"
      "Minimal" -> "car-11"
      _ -> ""
    end
  end
end
