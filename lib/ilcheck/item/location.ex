defmodule ILCheck.Item.Location do
  @enforce_keys [:type, :slot]
  defstruct(
    type: nil,
    page: nil,
    slot: nil,
    retainer: nil
  )

  alias __MODULE__

  def is_retainer_equipment(%Location{retainer: r, type: :equipment}, r), do: true
  def is_retainer_equipment(%Location{}, _), do: false

  def is_equipment(%Location{type: :equipment, retainer: nil}), do: true
  def is_equipment(%Location{type: :armory, retainer: nil}), do: true
  def is_equipment(%Location{}), do: false

  def is_saddlebag(%Location{type: :saddlebag}), do: true
  def is_saddlebag(%Location{}), do: false

  def is_inventory(%Location{type: :bag, retainer: nil}), do: true
  def is_inventory(%Location{}), do: false

  @doc """
  Sort locations: Retainer, equipment, saddlebag, inventory, other.

  This assists `ILCheck.Item.sort_best_to_worst` in sorting items.  We need
  this because you may have identical items (e.g. rings) that would otherwise
  confuse the planner into swapping items around needlessly.

  The sort key will also include the type, page, and slot.  As each slot should
  only have one item, this means item sort orders that include a location sort
  key should always be deterministic.
  """
  def sort_key(%Location{type: type, page: page, slot: slot} = loc) do
    uniq = {type, page_sort_key(type, page), slot}

    cond do
      !is_nil(loc.retainer) && loc.type != :market -> {1, uniq}
      is_equipment(loc) -> {2, uniq}
      is_saddlebag(loc) -> {3, uniq}
      is_inventory(loc) -> {4, uniq}
      loc.type in [:glamour, :armoire, :market] -> {5, uniq}
      loc -> raise "Not sure how to sort location: #{inspect(loc)}"
    end
  end

  def describe(%Location{retainer: nil} = l), do: describe_player(l.type, l.page, l.slot)
  def describe(%Location{retainer: r} = l), do: describe_retainer(r, l.type, l.page, l.slot)

  defp describe_player(:bag, page, slot), do: "inventory (#{page} / #{slot})"
  defp describe_player(:armory, type, slot), do: "armory (#{type} / #{slot})"
  defp describe_player(:equipment, nil, _), do: "equipment"
  defp describe_player(:saddlebag, side, slot), do: "saddlebag (#{side} / #{slot})"
  defp describe_player(:glamour, nil, nil), do: "glamour dresser"
  defp describe_player(:armoire, type, slot), do: "armoire (#{type} / #{slot})"

  defp describe_retainer(r, :equipment, nil, _), do: "#{r}'s equipment"
  defp describe_retainer(r, :market, nil, _), do: "#{r}'s market board"

  @char Application.get_env(:ilcheck, :character_name)
  if is_nil(@char), do: raise("You must specify a character name in `config/config.exs`.")

  @armory [
    weapon: "Main",
    offhand: "Offhand",
    head: "Head",
    body: "Body",
    hands: "Hand",
    legs: "Legs",
    feet: "Feet",
    earring: "Ear",
    necklace: "Neck",
    bracelet: "Wrist",
    ring: "Ring",
    soul: "Soul Crystal"
  ]

  def parse(@char, "Bag " <> rest) do
    [page, slot] = String.split(rest, " - ") |> Enum.map(&String.to_integer/1)
    %Location{type: :bag, page: page, slot: slot}
  end

  def parse(@char, "Saddlebag Left - " <> slot) do
    %Location{type: :saddlebag, page: :left, slot: String.to_integer(slot)}
  end

  def parse(@char, "Saddlebag Right - " <> slot) do
    %Location{type: :saddlebag, page: :right, slot: String.to_integer(slot)}
  end

  def parse(@char, "Glamour Chest") do
    %Location{type: :glamour, slot: nil}
  end

  def parse(@char, "Armoire - " <> rest) do
    [type, slot] = String.split(rest, " - ")
    %Location{type: :armoire, page: type, slot: String.to_integer(slot)}
  end

  def parse(@char, "Equipped Gear - " <> slot) do
    %Location{type: :equipment, slot: String.to_integer(slot)}
  end

  def parse(retainer, "Equipped Gear - " <> slot) do
    %Location{type: :equipment, retainer: retainer, slot: String.to_integer(slot)}
  end

  def parse(retainer, "Market - " <> slot) do
    %Location{type: :market, retainer: retainer, slot: String.to_integer(slot)}
  end

  @armory
  |> Enum.each(fn {key, name} ->
    def parse(@char, "Armory - #{unquote(name)} - " <> slot) do
      %Location{type: :armory, page: unquote(key), slot: String.to_integer(slot)}
    end
  end)

  def parse(char, location) do
    raise "Not sure where this item is: Character #{inspect(char)}, location #{inspect(location)}.  Do you have the wrong character name in `config/config.exs`?"
  end

  defp page_sort_key(:bag, page) when is_integer(page), do: page
  defp page_sort_key(:equipment, nil), do: nil
  defp page_sort_key(:market, nil), do: nil
  defp page_sort_key(:saddlebag, :left), do: 1
  defp page_sort_key(:saddlebag, :right), do: 2

  @armory
  |> Enum.with_index()
  |> Enum.each(fn {{key, _}, index} ->
    defp page_sort_key(:armory, unquote(key)), do: unquote(index)
  end)
end
