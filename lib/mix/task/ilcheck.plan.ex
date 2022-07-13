defmodule Mix.Tasks.Ilcheck.Plan do
  use Mix.Task

  @moduledoc false

  def run([csv]) do
    Logger.configure(level: :info)
    plan(csv)
  end

  def run(["-d", csv]) do
    Logger.configure(level: :debug)
    plan(csv)
  end

  def run(["--debug", csv]) do
    Logger.configure(level: :debug)
    plan(csv)
  end

  def run(_) do
    Mix.raise("Usage: mix ilcheck.plan [--debug] /path/to/export.csv")
  end

  defp plan(csv) do
    Logger.configure_backend(:console, Application.get_env(:logger, :console))

    output =
      case ILCheck.plan(csv) do
        [] ->
          "Nothing to do!"

        actions ->
          [
            "Suggested actions:\n",
            actions
            |> Enum.map(fn str -> " • #{str}" end)
            |> Enum.join("\n")
          ]
      end

    Logger.flush()
    IO.puts(["\n", output, "\n"])
  end
end
