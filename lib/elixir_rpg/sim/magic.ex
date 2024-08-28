defmodule ElixirRpg.Magic do
  defmodule Spells do
    use Lua.API, scope: "spell"

    def begin_casting(caster_id, cell_id),
      do:
        Lua.new()
        |> Lua.set!([:caster_id], caster_id)
        |> Lua.set!([:cell_id], cell_id)
        |> Lua.eval!("""
        --- empty stack used to handle spell clause outputs
        ret_stack = {}
        function push(val)
          table.insert(ret_stack, val)
        end

        function pop()
          return table.remove(ret_stack)
        end

        function peek()
          return ret_stack[1]
        end
        """)
        |> elem(1)
        |> Lua.load_api(__MODULE__)

    deflua closest_entity(), state do
      {cell, caster} = cell_and_caster(state)

      IO.puts("closest")

      {[], state}
    end

    deflua farthest_entity(), state do
      {cell, caster} = cell_and_caster(state)

      IO.puts("farthest")

      {[], state}
    end

    deflua heal(), state do
      {cell, caster} = cell_and_caster(state)

      IO.puts("heal")

      {[], state}
    end

    deflua hurt(), state do
      {cell, caster} = cell_and_caster(state)

      IO.puts("hurt")

      {[], state}
    end

    defp cell_and_caster(state),
      do: {
        state |> Lua.get!([:caster_id]) |> World.get_cell_by_id!(),
        state |> Lua.get!([:cell_id]) |> World.get_entity_by_id!()
      }
  end

  def words_to_spell(words) do
    words
    |> String.downcase()
    |> String.split()
    |> Enum.reduce_while(
      [],
      fn
        "osestcla", clauses ->
          {:cont, [:closest_entity | clauses]}

        "arthestfa", clauses ->
          {:cont, [:farthest_entity | clauses]}

        "ealha", clauses ->
          {:cont, [:heal | clauses]}

        "armha", clauses ->
          {:cont, [:harm | clauses]}

        _, clauses ->
          {:halt, :fizzle}
      end
    )
  end

  def interpret_spell(spell, caster_id, cell_id) do
    spell_source =
      spell
      |> Enum.map(fn
        :heal -> "spell.heal()"
        :harm -> "spell.harm()"
        :closest_entity -> "spell.closest_entity()"
        :farthest_entity -> "spell.farthest_entity()"
      end)
      |> Enum.join("\n")

    try do
      Spells.begin_casting(caster_id, cell_id)
      |> Lua.eval!(spell_source)

      :ok
    rescue
      _ -> :explode
    end
  end
end
