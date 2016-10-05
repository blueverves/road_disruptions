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
    # trigger the news feed
    GenEvent.sync_notify(manager, :start_feed)
    # get the disruptions stream
    stream = GenEvent.call(manager, DisruptionsFeedHandler, :disruptions)

    Logger.debug "DisruptionsChannel: push disruptions"

    # loop over the stream
    for disruption <- stream do
      Process.sleep(@delay)
      # send new feed entry to the client
      push socket, "new_disruption", %{disruption: disruption}
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
end
