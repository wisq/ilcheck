defmodule ILCheck do
  alias ILCheck.Item

  def parse(csv) do
    csv
    |> CSV.decode!(headers: true)
    |> Enum.map(&Item.parse/1)
  end
end
