defmodule ILCheck.Planner do
  require Logger

  defmodule Plan do
    defstruct(
      actions: %{},
      levels_used: %{},
      reserved_counts: %{},
      items_reserved: MapSet.new(),
      items_used: MapSet.new(),
      items_rejected: MapSet.new()
    )

    alias ILCheck.{Item, Item.Location}

    def restart(plan) do
      %Plan{plan | levels_used: %{}, reserved_counts: %{}}
    end

    def reserved_count(plan, category) do
      Map.get(plan.reserved_counts, category, 0)
    end

    def usable_count_by_level(plan, category, level) do
      Map.get(plan.levels_used, category, [])
      |> Enum.count(&(&1 <= level))
    end

    def accept_item(plan, item, timeframe) do
      plan
      |> add_to_items(:items_used, item)
      |> add_to_levels(item.category, item.level)
      |> move_item(item, :equipment, timeframe)
    end

    def reserve_item(plan, item, retainer) do
      plan
      |> add_to_items(:items_reserved, item)
      |> add_to_reserved_counts(item.category)
      |> move_item(item, {:retainer, retainer})
    end

    def reject_item(plan, item) do
      plan
      |> add_to_items(:items_rejected, item)
    end

    def skip_used_item(plan, item, :future) do
      plan
      |> add_to_levels(item.category, item.level)
    end

    def skip_used_item(plan, item, :current) do
      plan
      |> add_to_levels(item.category, item.level)
      # If an item was `:future` for a previous class,
      # but is `:current` for this one, this forces a move.
      |> move_item(item, :equipment, :current)
    end

    def skip_reserved_item(plan, item) do
      plan
      |> add_to_reserved_counts(item.category)
    end

    defp add_to_items(plan, key, item) do
      plan
      |> Map.update!(key, &MapSet.put(&1, item))
    end

    defp add_to_levels(plan, category, level) do
      levels =
        plan.levels_used
        |> Map.update(category, [level], &[level | &1])

      %Plan{plan | levels_used: levels}
    end

    defp add_to_reserved_counts(plan, category) do
      rc =
        plan.reserved_counts
        |> Map.update(category, 1, &(&1 + 1))

      %Plan{plan | reserved_counts: rc}
    end

    def move_item(plan, %Item{location: source} = item, target, timeframe \\ nil) do
      if !is_location(source, target, timeframe) do
        %Plan{plan | actions: map_put!(plan.actions, item, target)}
      else
        plan
      end
    end

    defp map_put!(map, key, new) do
      Map.update(map, key, new, fn
        ^new -> new
        old -> raise "Cannot update #{inspect(key)} to #{inspect(new)}, has value #{inspect(old)}"
      end)
    end

    defp is_location(loc, {:retainer, r}, _), do: Location.is_retainer_equipment(loc, r)
    defp is_location(loc, :garbage, _), do: Location.is_inventory(loc)

    defp is_location(loc, :equipment, :current), do: Location.is_equipment(loc)

    defp is_location(loc, :equipment, :future),
      do: Location.is_equipment(loc) || Location.is_saddlebag(loc)
  end

  alias ILCheck.{Class, Item, Item.Location}

  def plan_all(classes, items) when is_list(classes) do
    reserve_plan =
      classes
      |> Enum.filter(&(!is_nil(&1.retainer)))
      |> Enum.reduce(%Plan{}, &plan(&1, items, &2, :reserve_only))

    classes
    |> Enum.reduce(reserve_plan, &plan(&1, items, &2))
  end

  def plan(%Class{} = class, items, plan \\ %Plan{}, mode \\ nil) when is_list(items) do
    items
    |> Enum.reject(&ignore_equip?(&1, class))
    |> Enum.filter(&Item.usable_by_class(class, &1))
    |> Item.sort_best_to_worst(class.retainer)
    |> Enum.reduce(Plan.restart(plan), &plan_for_item(class, &1, &2, mode))
  end

  def tidy(%Plan{} = plan) do
    plan.items_rejected
    |> MapSet.difference(plan.items_reserved)
    |> MapSet.difference(plan.items_used)
    |> Enum.reject(&ignore_tidy?(&1))
    |> Enum.reduce(plan, &Plan.move_item(&2, &1, :garbage))
  end

  def describe_move({item, :garbage}) do
    "Discard \"#{item.name}\" from #{Location.describe(item.location)}."
  end

  def describe_move({item, {:retainer, name}}) do
    "#{name}: Equip \"#{item.name}\" from #{Location.describe(item.location)}."
  end

  def describe_move({item, :equipment}) do
    "Move \"#{item.name}\" from #{Location.describe(item.location)} to armoury chest."
  end

  defp want_count_for_category(:ring), do: 2
  defp want_count_for_category(_), do: 1

  defp plan_for_item(class, item, plan, mode) do
    cls = Class.name(class.key)
    wanted = want_count_for_category(item.category)
    reserved = if class.retainer, do: Plan.reserved_count(plan, item.category), else: 999
    timeframe = if item.level <= class.level, do: :current, else: :future

    cond do
      item in plan.items_reserved ->
        Logger.debug("#{cls}: Skipping #{describe(item)} -- reserved for retainer.")
        Plan.skip_reserved_item(plan, item)

      item in plan.items_used ->
        Logger.debug("#{cls}: Skipping #{describe(item)} -- already used in previous plan.")
        Plan.skip_used_item(plan, item, timeframe)

      reserved < wanted ->
        Logger.debug("#{cls}: Reserving #{describe(item)} for #{class.retainer}.")
        Plan.reserve_item(plan, item, class.retainer)

      mode == :reserve_only ->
        # We're in our initial reserve-only pass, and the retainer has enough gear
        # in this category, so completely skip the item for now.
        plan

      Plan.usable_count_by_level(plan, item.category, class.level) >= wanted ->
        Logger.debug("#{cls}: Rejecting #{describe(item)} -- obsolete.")
        Plan.reject_item(plan, item)

      Plan.usable_count_by_level(plan, item.category, item.level) >= wanted ->
        Logger.debug("#{cls}: Rejecting #{describe(item)} -- better item(s) available.")
        Plan.reject_item(plan, item)

      true ->
        Logger.debug("#{cls}: Accepting #{describe(item)} into #{timeframe} equipment.")
        Plan.accept_item(plan, item, timeframe)
    end
  end

  defp describe(item) do
    "#{item.name} (#{item.category}, #{item.level}/#{item.ilvl})"
  end

  @offhand_classes Class.crafters() ++ Class.gatherers() ++ [:PLD]

  defp ignore_equip?(item, class) do
    item.category == :soul ||
      item.location.type in [:armoire, :glamour] ||
      (item.category == :offhand && class.key not in @offhand_classes)
  end

  defp ignore_tidy?(item) do
    item.location.type in [:glamour, :armoire, :market]
  end
end
