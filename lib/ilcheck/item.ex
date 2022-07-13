defmodule ILCheck.Item do
  alias ILCheck.Class

  defstruct [:name, :category, :location, :level, :ilvl, :classes]
  alias __MODULE__

  def parse(row) do
    %Item{
      name: Map.fetch!(row, "Name"),
      category: Map.fetch!(row, "Category") |> parse_category(),
      location:
        parse_location(
          Map.fetch!(row, "Source"),
          Map.fetch!(row, "Location")
        ),
      level: Map.fetch!(row, "Item Level") |> String.to_integer(),
      ilvl: Map.fetch!(row, "iLevel") |> String.to_integer(),
      classes: Map.fetch!(row, "Equippable By") |> parse_classes()
    }
  end

  @arms Class.classes()
        |> Enum.flat_map(fn {_, name} ->
          %{
            "#{name}'s Arm" => :weapon,
            "Two-handed #{name}'s Arm" => :weapon,
            "#{name}'s Grimoire" => :weapon,
            "#{name}'s Primary Tool" => :weapon,
            "#{name}'s Secondary Tool" => :offhand
          }
        end)
        |> Map.new()

  @categories %{
                "Shield" => :offhand,
                "Head" => :head,
                "Body" => :body,
                "Hands" => :hands,
                "Legs" => :legs,
                "Feet" => :feet,
                "Earrings" => :earring,
                "Bracelets" => :bracelet,
                "Necklace" => :necklace,
                "Ring" => :ring
              }
              |> Map.merge(@arms)

  defp parse_category(category) do
    case Map.fetch(@categories, category) do
      {:ok, data} -> data
      :error -> raise "Unknown category: #{inspect(category)}"
    end
  end

  defp parse_location(_source, _location) do
    # WIP
  end

  defp parse_classes("Disciple of the Hand"), do: parse_classes("CRP BSM ARM GLA LTW WVR ALC CUL")
  defp parse_classes("Disciple of the Land"), do: parse_classes("MIN BTN FSH")

  defp parse_classes(classes) do
    classes
    |> String.split(" ")
    |> Enum.map(&Class.abbreviation_to_key/1)
  end
end
