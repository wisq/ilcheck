defmodule ILCheck.Class do
  @enforce_keys [:key]
  defstruct(
    key: nil,
    level: 0,
    retainer: false
  )

  alias __MODULE__

  def from_config(key, level) when is_integer(level) do
    %Class{key: key, level: level}
  end

  def from_config(key, %{level: _} = data) do
    data
    |> Map.put(:key, key)
    |> then(&struct!(Class, &1))
  end

  @war_names [
    ARC: "Archer",
    BRD: "Bard",
    DNC: "Dancer",
    DRG: "Dragoon",
    DRK: "Dark Knight",
    GLA: "Gladiator",
    GNB: "Gunbreaker",
    LNC: "Lancer",
    MCH: "Machinist",
    MNK: "Monk",
    MRD: "Marauder",
    NIN: "Ninja",
    PGL: "Pugilist",
    PLD: "Paladin",
    ROG: "Rogue",
    RPR: "Reaper",
    SAM: "Samurai",
    WAR: "Warrior"
  ]

  @magic_names [
    ACN: "Arcanist",
    AST: "Astrologian",
    BLM: "Black Mage",
    BLU: "Blue Mage",
    CNJ: "Conjurer",
    RDM: "Red Mage",
    SCH: "Scholar",
    SGE: "Sage",
    SMN: "Summoner",
    THM: "Thaumaturge",
    WHM: "White Mage"
  ]

  @crafter_names [
    ALC: "Alchemist",
    ARM: "Armorer",
    BSM: "Blacksmith",
    CRP: "Carpenter",
    CUL: "Culinarian",
    GSM: "Goldsmith",
    LTW: "Leatherworker",
    WVR: "Weaver"
  ]

  @gatherer_names [
    BTN: "Botanist",
    FSH: "Fisher",
    MIN: "Miner"
  ]

  @class_names @war_names ++ @magic_names ++ @crafter_names ++ @gatherer_names

  @war Keyword.keys(@war_names)
  @magic Keyword.keys(@magic_names)
  @crafters Keyword.keys(@crafter_names)
  @gatherers Keyword.keys(@gatherer_names)
  @classes Keyword.keys(@class_names)

  def class_names, do: @class_names

  def all, do: @classes
  def disciples_of_war, do: @war
  def disciples_of_magic, do: @magic
  def crafters, do: @crafters
  def gatherers, do: @gatherers

  @classes
  |> Enum.each(fn atom ->
    str = Atom.to_string(atom)
    def abbreviation_to_key(unquote(str)), do: unquote(atom)
  end)

  @class_names
  |> Enum.each(fn {atom, name} ->
    def name(unquote(atom)), do: unquote(name)
  end)
end
