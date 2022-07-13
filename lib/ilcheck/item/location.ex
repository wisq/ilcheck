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

  def is_inventory(%Location{type: :inventory, retainer: nil}), do: true
  def is_inventory(%Location{type: :saddlebag}), do: true
  def is_inventory(%Location{}), do: false

  @char Application.get_env(:ilcheck, :character_name)

  @armory %{
    "Main" => :weapon,
    "Offhand" => :offhand,
    "Head" => :head,
    "Body" => :body,
    "Hand" => :hands,
    "Legs" => :legs,
    "Feet" => :feet,
    "Ear" => :earring,
    "Wrist" => :bracelet,
    "Neck" => :necklace,
    "Ring" => :ring
  }

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
  |> Enum.each(fn {name, key} ->
    def parse(@char, "Armory - #{unquote(name)} - " <> slot) do
      %Location{type: :armory, page: unquote(key), slot: String.to_integer(slot)}
    end
  end)
end
