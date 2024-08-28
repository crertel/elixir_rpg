defmodule ElixirRpg.Magic do
  defmodule Spells do
    use Lua.API, scope: "spell"

    def begin_casting(caster_id, cell_id), do:
      Lua.new()
      |> Lua.set!([:caster_id], caster_id)
      |> Lua.set!([:cell_id], cell_id)
      |> Lua.eval!("""
      print "hi"
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
        print "okay"
      """)
      |> elem(1)
      |> Lua.load_api(__MODULE__)

    deflua closest_entity(), state do
      caster = Lua.get!(state, [:caster_id])
      cell = Lua.get!(state, [:cell_id])

      # get entity ref

      IO.puts "closest"
      {[], state}
    end

    deflua farthest_entity(), state do
      caster = Lua.get!(state, [:caster_id])
      cell = Lua.get!(state, [:cell_id])

      # get entity ref

      IO.puts "farthest"
      {[], state}
    end

    deflua heal(), state do
      caster = Lua.get!(state, [:caster_id])
      cell = Lua.get!(state, [:cell_id])

      IO.puts "heal"
      {[], state}
    end

    deflua hurt(), state do
      caster = Lua.get!(state, [:caster_id])
      cell = Lua.get!(state, [:cell_id])

      IO.puts "hurt"
      {[],state}
    end
  end


  def words_to_spell(words) do
    spell = words
    |> String.downcase()
    |> String.split()
    |> Enum.reduce_while([],
    fn "osestcla", clauses ->
      {:cont, [:closest_entity | clauses]}

      "arthestfa", clauses ->
        {:cont, [:farthest_entity | clauses]}

      "ealha", clauses ->
        {:cont, [:heal | clauses]}

      "armha", clauses ->
        {:cont, [:harm | clauses]}

      _, clauses->
        {:halt, :fizzle}
    end)
  end

  def interpret_spell(spell, caster_id, cell_id) do
    spell_source = spell
    |> Enum.map(fn
      :heal -> "spell.heal()"
      :harm -> "spell.harm()"
      :closest_entity -> "spell.closest_entity()"
      :farthest_entity ->"spell.farthest_entity()"
     end)
    |> Enum.join("\n")

    Spells.begin_casting(caster_id, cell_id)
    |> Lua.eval!(spell_source)
  end
end
