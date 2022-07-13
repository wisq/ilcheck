defmodule ILCheck do
  alias ILCheck.{Class, Item, Planner}
  require Logger

  def classes do
    Application.get_env(:ilcheck, :classes)
    |> classes()
  end

  def classes(list) do
    list
    |> Enum.map(fn {key, data} -> Class.from_config(key, data) end)
  end

  def parse(csv) do
    csv
    |> CSV.decode!(headers: true)
    |> Enum.map(&Item.parse/1)
  end

  def plan(csv_file) do
    items = File.stream!(csv_file) |> parse()
    plan = classes() |> Planner.plan_all(items) |> Planner.tidy()

    plan.actions
    |> Enum.sort_by(fn {item, _} -> Item.Location.sort_key(item.location) end)
    |> Enum.map(&Planner.describe_move/1)
  end
end
