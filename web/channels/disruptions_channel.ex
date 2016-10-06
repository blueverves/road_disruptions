defmodule RoadDisruptions.DisruptionsChannel do
  use RoadDisruptions.Web, :channel
  require Logger

  @delay 1000

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
    GenEvent.sync_notify(manager, :start_stream)
    # get the disruptions stream
    disruptions = GenEvent.call(manager, DisruptionsFeedHandler, :disruptions)

    Logger.debug "DisruptionsChannel: push disruptions"

    Process.sleep(@delay)
    # send new marker to the client
    push socket, "new_markers", %{markers: markers(disruptions)}
    # send new feed entry to the client
    push socket, "new_disruptions", %{disruptions: disruptions}

    {:reply, {:ok, payload}, socket}
  end

  def handle_in("next_dataset", payload, socket) do
    Logger.debug "DisruptionsChannel: next dataset"
    Process.sleep(@delay*2)

    # get stored GenEvent manager
    manager = get_in(socket.assigns, [:manager])
    # trigger the news feed
    GenEvent.sync_notify(manager, :next_dataset)
    # get the disruptions stream
    disruptions = GenEvent.call(manager, DisruptionsFeedHandler, :disruptions)

    Logger.debug "DisruptionsChannel: push disruptions"
    Process.sleep(@delay)
    # send new marker to the client
    push socket, "new_markers", %{markers: markers(disruptions)}
    # send new feed entry to the client
    push socket, "new_disruptions", %{disruptions: disruptions}

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
      %{location: disruption.location, status: disruption.status, display_point: disruption.cause_area.display_point, id: disruption.id}
    end)
  end
end
