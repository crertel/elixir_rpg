defmodule ElixirRpg.EntitiesPool do
  @moduledoc """
  Wrapper around an ETS table to handle getting entities.

  Supports manual indexing of things by cell or entity id.
  """
  alias ElixirRpg.Entity
  require ElixirRpg.Entity

  @entity_table :entity_table
  @cell_for_entity_table :cell_for_entity_table
  @entity_for_cell_table :entity_for_cell_table

  def init() do
    :ets.new(@entity_table, [:named_table, :public, :set])
    :ets.new(@cell_for_entity_table, [:named_table, :public, :set, {:read_concurrency, true}])
    :ets.new(@entity_for_cell_table, [:named_table, :public, :bag, {:read_concurrency, true}])
  end

  def create_entity(target_cell_id, Entity.entity(id: eid) = e) do
    etid = :ets.whereis(@entity_table)
    cfetid = :ets.whereis(@cell_for_entity_table)
    efctid = :ets.whereis(@entity_for_cell_table)

    :ets.insert(etid, {eid, e})
    :ets.insert(efctid, {target_cell_id, eid})
    :ets.insert(cfetid, {eid, target_cell_id})
  end

  def destroy_entity(Entity.entity(id: eid)) do
    etid = :ets.whereis(@entity_table)
    cfetid = :ets.whereis(@cell_for_entity_table)
    efctid = :ets.whereis(@entity_for_cell_table)

    if :ets.member(etid, eid) do
      if :ets.member(cfetid, eid) do
        [{^eid, cid}] = :ets.take(cfetid, eid)
        :ets.delete_object(efctid, {cid, eid})
      end

      :ets.delete(etid, eid)
    else
      :ok
    end
  end

  def get_entities_for_cell(cid) do
    etid = :ets.whereis(@entity_table)
    efctid = :ets.whereis(@entity_for_cell_table)

    if :ets.member(efctid, cid) do
      eids = :ets.lookup_element(efctid, cid, 2)
      Enum.map(eids, &:ets.lookup_element(etid, &1, 2))
    else
      []
    end
  end

  def get_cell_for_entity(Entity.entity(id: eid)) do
    etid = :ets.whereis(@entity_table)
    cfetid = :ets.whereis(@cell_for_entity_table)

    if :ets.member(etid, eid) and :ets.member(cfetid, eid) do
      :ets.lookup_element(cfetid, eid, 2)
    else
      nil
    end
  end

  def get_entity(eid) do
    etid = :ets.whereis(@entity_table)

    if :ets.member(etid, eid) do
      :ets.lookup_element(etid, eid, 2)
    else
      nil
    end
  end
end
