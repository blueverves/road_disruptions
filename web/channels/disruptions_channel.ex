defmodule RoadDisruptions.DisruptionsChannel do
  use RoadDisruptions.Web, :channel
  require Logger



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
    stream = StreamingXmlParser.run |> Stream.map(&(&1))
    Logger.debug "DisruptionsChannel: start stream"

    for disruption <- stream do
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
