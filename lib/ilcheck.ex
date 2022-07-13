defmodule ILCheck do
  alias ILCheck.{Class, Item}

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
end
