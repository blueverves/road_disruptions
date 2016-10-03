defmodule RoadDisruptions.PageController do
  use RoadDisruptions.Web, :controller

  def index(conn, _params) do
    disruptions = StreamingXmlParser.run |> Stream.map(&(&1)) |> Enum.take 20
    IO.inspect disruptions
    render conn, "index.html", disruptions: disruptions
  end
end
