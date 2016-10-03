defmodule RoadDisruptions.PageView do
  use RoadDisruptions.Web, :view

  def format_datetime(datetime) do
    case Timex.format(datetime, "{RFC1123}") do
      {:ok, fdatetime} -> fdatetime
      _ -> ""
    end
  end

  def format_point(point) do
    Enum.join(point, ", ")
  end
end
