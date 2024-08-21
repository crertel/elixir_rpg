defmodule ElixirRpg.Factions do
  @moduledoc false

  @factions ~w(
    shardfolk
    bearfolk
    spurriers
    holkhearts
    firas
    wosefolk
    smittelfolk
  )a

  def factions, do: @factions

  def faction_info(:shardfolk),
    do: %{
      display_name: "Shardfolk",
      selection_art: "/art/account_creation/shardfolk_preview.png",
      description: """
      Shardfolk are a race of crystalline beings, found years ago during firas mining exploration
      but soon found popping up everywhere in the Crossroads.

      Exhibiting an extreme aloofness and indifference to most mortals, they nonetheless can be
      useful contacts.
      """,
      self_description: """
      We are being inconvenienced by your presence. Please be moved from our sight, it is wished that we see the water with more clarity.

      Ah, many blessings may be received by you for this small favor. Now, what is to be your query to us?
      """,
      faction_prompt: """
      """
    }

  def faction_info(:bearfolk),
    do: %{
      display_name: "Bearfolk",
      selection_art: "/art/account_creation/bearfolk_preview.png",
      description: """
      Bearfolk are a race of sentient and bipedal bears that have inhabited the Crossroads
      since time out of mind.

      Relaxed--some say lazy--and friendly, slow to anger, and quite strong they make
      excellent traveling companions.
      """,
      self_description: """
      ʕ•ᴥ•ʔ
      """,
      faction_prompt: """
      """
    }

  def faction_info(:spurriers),
    do: %{
      display_name: "spurriers",
      selection_art: "/art/account_creation/spurriers_preview.png",
      description: """
      Spurriers are the most recent newcomers to the Crossroads, growing in number
      in the past seasons.

      They are generally harmless but tend towards extreme curiosity, investigating the land
      around them and asking lots of questions.

      They are seldom seen outside of their environmental hazard suits, and
      often carry strange otherworldy equipment.

      It is rumored that they come from the same place as the holkhearts.
      """,
      self_description: """
      Hello, thank you for taking the time to help with our survey. We're new to these lands, and could use somebody of your talents.
      Do you happen to know how to read a topographic map or use a laser rangefinder?

      No, no, we've got protection for the survey team--we just need an extra set of hands.
      """,
      faction_prompt: """
      """
    }

  def faction_info(:holkhearts),
    do: %{
      display_name: "holkhearts",
      selection_art: "/art/account_creation/holkheart_preview.png",
      description: """
      Holkhearts are the second most recent newcomers to the Crossroads,
      appearing in ever great number in the past couple of years.

      They are extremely dangerous, carrying metal weapons that clap and spark loudly,
      capable of killing goodfolk hundreds of strides away.

      They mostly keep to their own kind and follow a sort of strict hierarchy, but occasionally
      one or two may be found and brought in to help with thornier problems--for the right price,
      of course.

      It is rumored that they come from the same place as the spurriers.
      """,
      self_description: """
      Step back, hands out. This area is restricted to all non-human personnel. This is your final warning.

      What? Who are we? That's not important--scatter or be scattered.
      """,
      faction_prompt: """
      """
    }

  def faction_info(:firas),
    do: %{
      display_name: "Firas",
      selection_art: "/art/account_creation/firas_preview.png",
      description: """
      Firas have been in the Crossroads long enough that their origins are forgotten, though it is rumored
      that they are the remnants of a once great civilization.

      Typically living as butchers, farmers, smiths, fishermen, artisans, and merchants, firas are
      notable for their variety and numbers.

      As the saying goes, "if you ken one firas, you ken one firas". No two are exactly alike, and their
      dispositions and abilities vary widely.
      """,
      self_description: """
      Aye, I see you there. I'm behired right now, but in a fortnight I'll be free and can help you fasten your firelock.
      I'm a clever artificer, and haven't yet met the work that I can't do.
      """,
      faction_prompt: """
      """
    }

  def faction_info(:wosefolk),
    do: %{
      display_name: "Wosefolk",
      selection_art: "/art/account_creation/wosefolk_preview.png",
      description: """
      Wosefolk appeared during the Bleered Stour several spans ago, their great green forms emerging from portals
      and scattering in camps across the Crossroads.

      Large, clever, and possessing great stamina, they frequently work as merchants due to their ability to carry
      heavy goods long distances and haggle once they arrive.

      They make for good companions and terrible enemies, and excel at the husbandry of business.
      """,
      self_description: """
      It is a pleasure to make your acquaintance, my dear customer. What might you be wanting from my humble shop?

      I have spices from across the Crossroads, deeds to idyllic parcels in lush lands, and even holkheart coin.

      Whatever you need, my friend, I am happy to arrange. If I don't have it, I'm sure my kin do.
      """,
      faction_prompt: """
      """
    }

  def faction_info(:smittelfolk),
    do: %{
      display_name: "Smittelfolk",
      selection_art: "/art/account_creation/smittelfolk_preview.png",
      description: """
      Once firas--or at least, rumored to be--but now something completely corrupted, the smittlefolk are
      abonimiations to the natural order and permanent reminders of the foolishness of those that came before.

      Consisting of animated corpses puppeted by a shoal of vermin and wyrmlings these monstrosities yet speak and move,
      doubtless attempting to spread and subvert goodfolk.

      Though they appear articulate and kind, do not trust these creatures.

      It is rumored that many smittelfolk possess first-hand knowledge of distant ages and deeds long finished.
      """,
      self_description: """
      See/feel your presence friendmeat. Come/lean closer, we have such tales/sorrow to tell you. Rest/spend your time/essence here.

      No, we/I/us have not met/seen/consumed your companion/friend/meat. Please share this drink/fluid/meal with us.

      We/us/all are so very bored/lonely/starving.
      """,
      faction_prompt: """
      """
    }
end
