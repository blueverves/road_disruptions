defmodule StreamingXmlParser do
  import SweetXml
  require Logger

  @endpoint "https://data.tfl.gov.uk/tfl/syndication/feeds/tims_feed.xml"
  @uri "#{@endpoint}?app_id=#{Application.get_env(:road_disruptions, RoadDisruptions.Endpoint)[:tims_app_id]}&app_key=#{Application.get_env(:road_disruptions, RoadDisruptions.Endpoint)[:tims_app_key]}"
  @timeout 2500
  @recv_timeout 7000

  def run do
    Stream.resource(
      fn -> open_feed end,
      fn stream ->
        case parse_xml(stream) do
          data when is_list(data) -> {data, stream}
          _ -> {:halt, stream}
        end
      end,
      fn data -> data end
    )
  end

  defp open_feed do
    Logger.debug "StreamingXmlParser: open_feed"
    HTTPoison.start
    {:ok, %HTTPoison.Response{body: data}} = HTTPoison.get(@uri, [], [timeout: @timeout, recv_timeout: @recv_timeout])
    data
  end

  defp parse_xml(stream) do
    Logger.debug "StreamingXmlParser: parse_xml"

    stream |> xpath(
      ~x"//Disruption"l,
      id: ~x"./@id/text()"s,
      status: ~x"./status/text()"s,
      severity: ~x"./severity/text()"s,
      level_of_interest: ~x"./levelOfInterest/text()"s,
      category: ~x"./category/text()"s,
      sub_category: ~x"./subCategory/text()"s,
      start_time: ~x"./startTime/text()"s |> transform_by(&parse_datetime(&1)),
      end_time: ~x"./endTime/text()"s |> transform_by(&parse_datetime(&1)),
      location: ~x"./location/text()"s,
      corridor: ~x"./corridor/text()"s,
      comments: ~x"./comments/text()"s,
      current_update: ~x"./currentUpdate/text()"s,
      remark_time: ~x"./remarkTime/text()"s |> transform_by(&parse_datetime(&1)),
      last_mod_time: ~x"./lastModTime/text()"s |> transform_by(&parse_datetime(&1)),
      cause_area: [
        ~x"./CauseArea",
        display_point: ~x"./DisplayPoint/Point/coordinatesLL/text()"s |> transform_by(&format_point/1),
        streets: [
          ~x"./Streets/Street"l,
          name: ~x"./name/text()"s,
          closure: ~x"./closure/text()"s,
          directions: ~x"./directions/text()"s
        ]
      ]
    )
  end

  def format_point(str) do
    if String.contains?(str, ",") do
      String.split(str, ",")
      |> Enum.map(fn(token) -> 
        token
        |> String.replace_leading("-.", "-0.")
        |> String.replace_leading(".", "0.")
      end)
    else
      str
    end
  end

  defp parse_datetime(str) do
    case String.length(str) do
      19 ->
        str = str <> "Z"
        {:ok, datetime} = Timex.parse(str, "{ISO:Extended:Z}")
      20 ->
        {:ok, datetime} = Timex.parse(str, "{ISO:Extended:Z}")
      _ -> datetime = nil
    end
    datetime
  end

end
