
# Elixir RPG development
## Trials and Tribulations

---

# Who are you?

I'm an Elixir devloper, with about a decade in the language.

I'm a game developer, mostly in C/C++/Javascript.

I'm a graphics programmer, having done 2D/3D/CAD software.

I'm an artist, mostly at the "programmer art" level. 

I'm currently working as Head of Engineering at GetThru, leading a great team of people.

**I'm a generalist.**

---

# Obligatory Plug

**GO ATTEND BRIAN MEEKER'S RABBITMQ TALK**

(not even kidding.)

---

Part 0: Prelude

> We do these things not becaue they are easy, but because we thought they would be easy.

---

# Why game development in Elixir and Phoenix?

To answer this, we first need to ask--why game development?

---

## Game development is *fun*.

It's a bunch of puzzles, and you get to mess around with the results as you play.

---

## Game development is *hard*.

The sorts of games I work on are simulations, which are intricate and which are close to how computers are intended to work.

---

## Game development is *liberating*.

Our jobs tend to have systems people need to work, built on codebases we morlochs hate to maintian but are bribed to.

For a small game project, nobody cares if I add bugs.

Nobody cares if I try something suboptimal.

Nobody cares if I add something I find neat.

That's freeing.

---

# Okay, but why Phoenix and Elixir?

I'll let you in on something:

I'm weird. I'm strange. I'm curious.

I want to use the wrong tool for the job and see how far I can get.

---

If you're building a game from scratch, you basically a server like this:

```
while (game.is_running) {
  events = get_client_events(game.clients);
  newState = update(game.oldState, events);
  send(newState, game.clients);
}
```
-

And for the client, something like this:

```
while (game.is_running and game.is_connected) {
  inputEvents = get_input_events();
  serverEvents = get_server_events();
  game.state = update(game.oldState, inputEvents, serverEvents);
  notifyServer(input);
  render(game.state);
};

---

The core idea is that you take in events, you update your state with them, you render that state, and you loop.

That core idea still leaves a lot of quesitons, though.

---

* Do you process the game objects serially or concurrently?
* Do objects just get to do whatever they want, or is it orchestrated?
* How do objects cause changes to happen on other objects?
* Are objcets allowed to chnage their behavior? If so, how is that handled?
* Are objects allowed to change their state schema?

---

To answer these questions, a technique called Entity Component Systems was developed.

Objects--entities--are collections of handles to components, such as position, rendering information, collision information, etc.

The components are read from by the systems, updated, and written back out to.

Two key advantages to this:

* Entities can have plug-and-play components -> great for authoring!
* Components can be allocated in chunks of contiguous memory -> great for speed!

---

On the flipside though:

* Can be hard to get sequencing of systems to work correctly.
* The BEAM means contiguous memory allocations kinda don't matter.
* Expressing game logic in terms of components can be awkward.

---

So, let's see how I tackled these problems.

---

Part 1: Scoping the game

---

Gamedev common mistake:

**Build the tech and ignore the game.**

(I have done this. Multiple times.)

---

Let's talk about what we want in the game:

* I want a world with houses I can go into and out of.
* I want walls I can't walk past.
* I want floors of different shapes and textures.
* I want to be able to cast spells.
* I want to be able to talk to people.
* I want to hvae multiple people connected at once.

--

On the technical side, that's where we're Gonna Get Weird:

* I want to do all of my rendering in SVGs via LiveView.
* I want to use GenServers, but not too much GenServers.
* I want to have the magic system scriptable.
* I want to not use Ecto.
* I want to not use nifs.

--

Every single one of those technical choices gave me a headache.

---

Not using nifs?

Okay, gotta be a little worried about performance, but that's okay.

---

Not using Ecto?

Slightly more annoying, but it really just means I want to avoid using forms for input.

It also meant I gave up on some rapid iteration tooling a previous attempt had, but that's ultimately for the better.

---

Scriptbale magic system?

Well, again, kinda weird, but Lua has a few wrappers for Elixir, so we're okay there.

---

Not too much GenServers?

Hooo boy.

