
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

**GO ATTEND BRIAN MEEKER'S TALK**

(not even kidding.)

---

## Acknowledgements

I'd like to thank:

* Isaac Yonemoto
* Aos Dabbagh
* Distractions
* Dorian

---

# Part 0: Prelude

> We do these things not becaue they are easy, but because we thought they would be easy.

---

# Why game development in Elixir and Phoenix?

---

## Game development is *fun*.

It's a bunch of puzzles, and you get to mess around with the results as you play.

---

## Game development is *hard*.

The sorts of games I work on are simulations, which are intricate and which are close to how computers are intended to work.

---

## Game development is *liberating*.

---

# Okay, but why Phoenix and Elixir?

---

If you're building a game from scratch, you basically a server like this:

```
while (game.is_running) {
  events = get_client_events(game.clients);
  newState = update(game.oldState, events);
  send(newState, game.clients);
}
```

---

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


## Events -> Upate -> Render -> Repeat

---

## But...

* Do you process the game objects serially or concurrently?
* Do objects just get to do whatever they want, or is it orchestrated?
* How do objects cause changes to happen on other objects?
* Are objcets allowed to chnage their behavior? If so, how is that handled?
* Are objects allowed to change their state schema?


---

I want to try to find answers to these questions.

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
* I want to have multiple people connected at once.

---

On the technical side, that's where we're Gonna Get Weird:

* I want to do all of my rendering in SVGs via LiveView.
* I want to use GenServers, but not too much GenServers.
* I want to have the magic system scriptable.
* I want to not use Ecto.
* I want to not use nifs.

--

## Every single one of those technical choices made life harder.

---

# Every.

---

# Single.

---

# One.

---

Again, my hubris:

* I want to do all of my rendering in SVGs via LiveView.
* I want to use GenServers, but not too much GenServers.
* I want to have the magic system scriptable.
* I want to not use Ecto.
* I want to not use nifs.

---

# Part 2: NPC Chat

---

# A theory of NPC knowledge

---

## Result?

---

**FAILURE. ETIMEOUT**

---

## Why?

---

# Part 3: Magic System

---

## What if wizards were programmers?

---

## Result?

---

**Partal success!**

---

## Why?

---

# Part 4: SVG rendering

---

# A tale of too-clever-by-half

---

## Result?

---

**Partial success!**

---

## An attempted fix.

---

(demo)

---

# Other adventures

---

## Logging

---

## Dashboard plugins

---

# Development gallery