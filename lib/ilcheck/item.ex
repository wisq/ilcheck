defmodule ILCheck.Item do
  alias ILCheck.Class
  alias ILCheck.Item.Location

  defstruct [:name, :category, :location, :level, :ilvl, :classes]
  alias __MODULE__

  @doc "Parse a CSV row into an item."
  def parse(row) do
    %Item{
      name: Map.fetch!(row, "Name"),
      category: Map.fetch!(row, "Category") |> parse_category(),
      location:
        Location.parse(
          Map.fetch!(row, "Source"),
          Map.fetch!(row, "Location")
        ),
      level: Map.fetch!(row, "Item Level") |> String.to_integer(),
      ilvl: Map.fetch!(row, "iLevel") |> String.to_integer(),
      classes: Map.fetch!(row, "Equippable By") |> parse_classes()
    }
  end

  def usable_by_class(%Class{key: key}, %Item{} = item) do
    key in item.classes
  end

  @doc """
  Sort a list of items such that the best items go first.

  Primary sorting key is the iLvl, but in the case that two items have the same
  iLvl, the item that requires the lowest level to equip will come first.

  Thus, a 530/80 Cryptlurker item will be considered better than a 530/83
  Imperial item, since it gives the same bonuses but can be equipped sooner
  (and we don't need to clutter our inventory with an extra item).
  """
  def sort_best_to_worst(items) do
    items
    |> Enum.sort_by(&sort_key/1)
  end

  defp sort_key(%Item{level: level, ilvl: ilvl}) do
    {-ilvl, level}
  end

  #
  # Rest of this file is internal functions and lookup tables used for parsing.
  #
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

  @gear %{
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

  @categories Map.merge(@arms, @gear)

  defp parse_category(category) do
    case Map.fetch(@categories, category) do
      {:ok, data} -> data
      :error -> raise "Unknown category: #{inspect(category)}"
    end
  end

  defp parse_classes("Disciple of the Hand"), do: parse_classes("CRP BSM ARM GLA LTW WVR ALC CUL")
  defp parse_classes("Disciple of the Land"), do: parse_classes("MIN BTN FSH")

  defp parse_classes(classes) do
    classes
    |> String.split(" ")
    |> Enum.map(&Class.abbreviation_to_key/1)
  end
end
