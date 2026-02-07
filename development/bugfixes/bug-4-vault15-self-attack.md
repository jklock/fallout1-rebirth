# Bug 4: Vault 15 self-attack regression (ladder transitions)

Last updated: 2026-02-07

## Report
In Vault 15 (ladder to underground), entering combat immediately causes
self-attack. Sporadic reports in Junktown after climbing from underground.

## Known Fix in History
Commit: d147705 ("prevent self-attack combat bug in Vault 15")
- src/game/combat.cc: validate whoHitMe on load (avoid self/same-team).
- src/game/critter.cc: critter_set_who_hit_me() rejects self/same-team.
- src/int/support/intextra.cc: op_attack_setup uses critter_set_who_hit_me().

## Why It Might Regress
- Some path still sets whoHitMe directly without using the setter.
- Map transition/ladder scripts may set combat state in a different code path.
- combat_load() validation only covers combat list restore; if the bug
  is triggered post-load, it bypasses this guard.

## Relevant Code
- src/game/combat.cc (combat_load)
- src/game/critter.cc (critter_set_who_hit_me)
- src/int/support/intextra.cc (op_attack_setup)

## Repro Checklist
1) Vault 15: descend ladder, observe instant combat/self-attack
2) Junktown: ascend from underground, observe sporadic self-attack
3) Capture save just before transition for debugging

## Investigation Tasks
- Search for direct writes to critter->data.critter.combat.whoHitMe.
- Verify all attack setup paths go through critter_set_who_hit_me().
- Log attacker/defender/team on ladder transitions to see whoHitMe values.

## Candidate Fixes
- Replace remaining direct whoHitMe assignments with critter_set_who_hit_me().
- Add an additional guard in combat turn start to clear whoHitMe if it
  points to self or same team.

