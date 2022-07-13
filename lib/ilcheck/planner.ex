defmodule ILCheck.Planner do
  defmodule Plan do
    defstruct(
      actions: %{},
      lowest_levels: %{},
      items_used: [],
      items_rejected: []
    )
  end

  alias ILCheck.{Class, Item, Item.Location}

  def plan(%Class{} = class, items) when is_list(items) do
    items
    |> Enum.filter(&Item.usable_by_class(class, &1))
    |> Item.sort_best_to_worst()
    |> Enum.reduce(%Plan{}, &plan_for_item(class, &1, &2))
  end

  defp plan_for_item(class, item, plan) do
    lowest_level = plan.lowest_levels |> Map.get(item.category)

    cond do
      is_nil(lowest_level) and !is_nil(class.retainer) ->
        accept_item(plan, item, {:retainer, class.retainer})

      is_nil(lowest_level) ->
        accept_item(plan, item, :equipment)

      item.level < lowest_level ->
        accept_item(plan, item, :equipment)

      item.level >= lowest_level ->
        reject_item(plan, item)
    end
  end

  defp accept_item(plan, item, destination) do
    %Plan{
      plan
      | lowest_levels: plan.lowest_levels |> Map.put(item.category, item.level),
        items_used: [item | plan.items_used]
    }
    |> move_item(item, destination)
  end

  defp reject_item(plan, item) do
    %Plan{plan | items_rejected: [item | plan.items_rejected]}
  end

  defp move_item(plan, %Item{location: source} = item, target) do
    if !is_location(source, target) do
      %Plan{plan | actions: map_put!(plan.actions, item, target)}
    else
      plan
    end
  end

  defp map_put!(map, key, value) do
    Map.update(map, key, value, fn old ->
      raise "Cannot update #{inspect(key)} to #{inspect(value)}, has value #{inspect(old)}"
    end)
  end

  defp is_location(loc, {:retainer, r}), do: Location.is_retainer_equipment(loc, r)
  defp is_location(loc, :equipment), do: Location.is_equipment(loc)
  defp is_location(loc, :inventory), do: Location.is_inventory(loc)
end
