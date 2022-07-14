# Copy this to config.exs and fill in your data.
import Config

config :logger, level: :info
config :logger, :console, format: "$metadata[$level] $message\n"

config :ilcheck,
  character_name: "YourFull CharacterName",
  # Classes must be in either long form,
  #   WAR: %{level: 90, ...},
  # or in short form:
  #   WAR: 90,
  classes: [
    # Tanks:
    PLD: 11,
    WAR: %{level: 90, retainer: "Retainer1Name"},
    DRK: 22,
    GNB: 33,
    # Healers:
    WHM: 44,
    SCH: 55,
    AST: 66,
    SGE: 77,
    # Melee DPS:
    MNK: 88,
    DRG: 12,
    NIN: 34,
    SAM: 56,
    RPR: 78,
    # Ranged DPS:
    BRD: 90,
    MCH: %{level: 90, retainer: "Retainer2Name"},
    DNC: 87,
    # Magical DPS:
    BLM: 65,
    # SMN should be the same as SCH ;)
    SMN: 55,
    RDM: 54,
    # Limited jobs:
    BLU: 32
  ]
