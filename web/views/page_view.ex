defmodule RoadDisruptions.PageView do
  use RoadDisruptions.Web, :view

  def format_point(point) do
    Enum.join(point, ", ")
  end
end
