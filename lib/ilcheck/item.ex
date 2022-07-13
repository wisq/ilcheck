defmodule ILCheck.Item do
  alias ILCheck.Class
  alias ILCheck.Item.Location

  @enforce_keys [:name, :category, :location, :level, :ilvl, :classes, :quality]
  defstruct @enforce_keys
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
      classes: Map.fetch!(row, "Equippable By") |> parse_classes(),
      quality: Map.fetch!(row, "Type") |> parse_quality()
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

  As a final tie-breaker, we sort items on their location.  See
  `ILCheck.Location.sort_key/1` for details.
  """
  def sort_best_to_worst(items) do
    items
    |> Enum.sort_by(&sort_key/1)
  end

  defp sort_key(%Item{level: level, location: loc} = item) do
    {-effective_ilvl(item), level, Location.sort_key(loc)}
  end

  #
  # Rest of this file is internal functions and lookup tables used for parsing.
  #
  @arms Class.class_names()
        |> Enum.flat_map(fn {_, name} ->
          %{
            "#{name}'s Arm" => :weapon,
            "One-handed #{name}'s Arm" => :weapon,
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
    "Ring" => :ring,
    "Soul Crystal" => :soul
  }

  @categories Map.merge(@arms, @gear)

  defp parse_category(category) do
    case Map.fetch(@categories, category) do
      {:ok, data} -> data
      :error -> raise "Unknown category: #{inspect(category)}"
    end
  end

  defp parse_classes("Disciple of the Hand"), do: Class.crafters()
  defp parse_classes("Disciple of the Land"), do: Class.gatherers()
  defp parse_classes("Disciple of War"), do: Class.disciples_of_war()
  defp parse_classes("Disciple of Magic"), do: Class.disciples_of_magic()
  defp parse_classes("All Classes"), do: Class.all()

  defp parse_classes("Disciples of War or Magic"),
    do: Class.disciples_of_war() ++ Class.disciples_of_magic()

  defp parse_classes(classes) do
    if classes =~ ~r/^[A-Z ]+$/ do
      classes
      |> String.split(" ")
      |> Enum.map(&Class.abbreviation_to_key/1)
    else
      raise "Unknown class: #{inspect(classes)}"
    end
  end

  defp parse_quality("HQ"), do: :hq
  defp parse_quality("NQ"), do: :nq

  # NQ Neo-Ishgardian (480) is worse than Deepshadow (470).
  defp effective_ilvl(%Item{name: "Neo-Ishgardian" <> _, quality: :nq, ilvl: ilvl}), do: ilvl - 20
  # NQ Exarchic (510) is worse than Crystarium (500).
  defp effective_ilvl(%Item{name: "Exarchic" <> _, quality: :nq, ilvl: ilvl}), do: ilvl - 20
  defp effective_ilvl(%Item{ilvl: ilvl}), do: ilvl
end
