defmodule StreamingXmlParser do
  import SweetXml

  @endpoint "https://data.tfl.gov.uk/tfl/syndication/feeds/tims_feed.xml"
  @uri "#{@endpoint}?app_id=#{System.get_env("TIMS_APP_ID")}&app_key=#{System.get_env("TIMS_APP_KEY")}"
  @timeout 2500
  @recv_timeout 7000

  def run do
    Stream.resource(
      fn -> open_feed end,
      fn stream ->
        case parse_xml(stream) do
          data when is_list(data) and data != [] ->
            {data, stream}
          _ ->
            {:halt, stream}
        end
      end,
      fn stream -> stream end
    )
  end

  defp open_feed do
    HTTPoison.start
    {:ok, %HTTPoison.Response{body: data}} = HTTPoison.get(@uri, [], [timeout: @timeout, recv_timeout: @recv_timeout])
    data
  end

  defp parse_xml(stream) do
    IO.puts ">>> parse_xml"
    stream |> xpath(
      ~x"//Disruption"l,
      id: ~x"./@id/text()"s,
      status: ~x"./status/text()"s,
      severity: ~x"./severity/text()"s,
      level_of_interest: ~x"./levelOfInterest/text()"s,
      category: ~x"./category/text()"s,
      sub_category: ~x"./subCategory/text()"s,
      start_time: ~x"./startTime/text()"s,
      end_time: ~x"./endTime/text()"s,
      location: ~x"./location/text()"s,
      corridor: ~x"./corridor/text()"s,
      comments: ~x"./comments/text()"s,
      current_update: ~x"./currentUpdate/text()"s,
      remark_time: ~x"./remarkTime/text()"s,
      last_mod_time: ~x"./lastModTime/text()"s,
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

end
