# Actor state registry

This document defines ownership of mutable state while a LAN host simulates
both the local player and one guest. The executable field lists live in
`src/actor_context.lua`; `ActorContext.state_registry()` exposes them to tests.

## Actor-owned state

- The complete player/ghost table (`ActorState`/`GhostActor`): inventory,
  equipment, carried block, stats, buffs, animation, movement, quests and
  personal progress.
- `ActorRegistry` runtime input and interpolation state.
- `presentation.local_ui.game`: craft visibility, achievements/input widgets
  and actor-scoped movement/action cooldown flags listed as `game_fields`.
- `presentation.local_ui.craft`: pointer, eligible recipes and temporary craft
  calculation fields listed as `craft_fields`.
- `runtime.local_globals`: legacy actor globals listed as `actor_globals`
  (`fishing` at present).
- Globals listed as `transient_globals` are scratch values. They are cleared on
  context entry and restored afterwards; their guest value is never persisted.

New actor-owned state should normally be added to the actor or its runtime
sidecar. A legacy field may use `ActorContext.register_field(scope, name)` only
as an explicit migration step with an isolation test.

## Shared authoritative state

- `world`, `mobs`, `proj`, `worldani`, `tips` and `disp`.
- World time and world TTL/check lists in `game`.
- Item identities and the world journal.

Only the host mutates shared state. Guest actions enter through
`multiplayer_guest_action`; guest simulation records resulting world changes
for replication.

## Host-only state

- Save manager and save slot ownership.
- Host `Session`, ENet listener, discovery advertiser and world journal.
- Approval, drop/recovery and shutdown orchestration.

This state must never be swapped into a guest context or serialized as guest
presentation state.

## Presentation-only state

- Per-actor camera and `presentation.local_ui` sidecars.
- Active `vi`, mouse/aim projection and local audio/HUD ownership.
- Client interpolation queues and render clock.

Presentation state is not saved as authoritative world state.

## Review checklist

For every new mutable global or `game` field:

1. Classify it as shared, host-only, guest/actor-owned or local presentation.
2. Prefer actor/runtime fields for actor-owned data; document any temporary
   `ActorContext.register_field` use.
3. If shared, prove that only the host mutates it and that replication/save
   semantics are explicit.
4. Add host/guest sentinel coverage for actor-owned state and exercise both a
   simulation and an action path.
5. Verify exception restoration when the field participates in a callback.
