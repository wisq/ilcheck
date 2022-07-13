defmodule ILCheck.Class do
  @enforce_keys [:key]
  defstruct(
    key: nil,
    level: 0,
    retainer: false
  )

  @classes [
    ACN: "Arcanist",
    ALC: "Alchemist",
    ARC: "Archer",
    ARM: "Armorer",
    AST: "Astrologian",
    BLM: "Black Mage",
    BLU: "Blue Mage",
    BRD: "Bard",
    BSM: "Blacksmith",
    BTN: "Botanist",
    CNJ: "Conjurer",
    CRP: "Carpenter",
    CUL: "Culinarian",
    DNC: "Dancer",
    DRG: "Dragoon",
    DRK: "Dark Knight",
    FSH: "Fisher",
    GLA: "Gladiator",
    GNB: "Gunbreaker",
    GSM: "Goldsmith",
    LNC: "Lancer",
    LTW: "Leatherworker",
    MCH: "Machinist",
    MIN: "Miner",
    MNK: "Monk",
    MRD: "Marauder",
    NIN: "Ninja",
    PGL: "Pugilist",
    PLD: "Paladin",
    RDM: "Red Mage",
    ROG: "Rogue",
    RPR: "Reaper",
    SAM: "Samurai",
    SCH: "Scholar",
    SGE: "Sage",
    SMN: "Summoner",
    THM: "Thaumaturge",
    WAR: "Warrior",
    WHM: "White Mage",
    WVR: "Weaver"
  ]

  def classes, do: @classes

  @classes
  |> Enum.each(fn {atom, _} ->
    str = Atom.to_string(atom)
    def abbreviation_to_key(unquote(str)), do: unquote(atom)
  end)
end
