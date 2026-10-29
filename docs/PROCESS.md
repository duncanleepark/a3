# Development Record

## Task 1: Move around a tiny hand-built world and see the updated position

Planned behavior: Build a small map from explicit data, place the camel, and
apply movement and wait actions. The camel should move one cell per legal
action. Moving into a wall or outside the map should change nothing,
including the turn count. Waiting should leave the camel in place and consume
one turn.

Planned check: Construct a hand-built world and apply a blocked move, a legal
move, and a wait. The blocked move should leave the camel and turn count
unchanged. The legal move should update the camel position and increment the
turn count. The wait should increment the turn count without moving the camel.

Actual check and result: The OUnit tests `game blocked move`, `game collects
lambda`, and `game wait` construct worlds with `World.from_setup`, apply
`Game.act`, and inspect the resulting positions and turn counts. The blocked
move leaves the camel at `(3, 1)` with zero turns. The legal move changes the
position and increments the turn count. The wait increments the turn count
while leaving the camel in place. These checks passed.

Decision or revision: Movement and turn handling remain in `Game.act`, while
map construction remains in `World.from_setup`. This keeps movement rules
independent of terminal input.

## Task 2: Fog of war reveals a cross and stays revealed

Planned behavior: Before the first input, reveal the camel's cell and its
in-bounds orthogonal neighbors. After a successful move or wait, reveal the
same cross at the camel's new position. Revealed cells should remain revealed,
and cells beyond an adjacent wall should remain hidden.

Planned check: Construct a small world with the camel near a wall. Check the
initial camel and neighboring cells, verify that an adjacent wall is revealed,
and verify that a cell beyond that wall is hidden.

Actual check and result: The OUnit tests `game initial reveal` and `fog stops
at wall` inspect `Game.is_revealed`. The camel's initial cross is revealed, a
wall adjacent to the camel is visible, and the cell beyond that wall remains
hidden. The tests passed.

Decision or revision: Fog state is stored as a separate Boolean 2D array in
`Game.t`. This prevents rendering or actor visibility from changing the world
terrain.

## Task 3: Collect a lambda once and track the score

Planned behavior: Entering a lambda cell should add its value to the score and
remove it permanently. Copper, silver, and gold should be worth 1, 3, and 5
points respectively.

Planned check: Place a silver lambda next to the camel, enter it, leave it,
and enter it again. The score should increase to 3 on the first visit and
remain 3 on the second visit. The lambda should no longer be present.

Actual check and result: The OUnit tests `game collects lambda` and `game
collects lambda once` move onto a silver lambda, inspect the score, inspect
`World.lambda_at`, and revisit the cell. The score becomes 3, the lambda is
removed, and the score does not increase on revisiting. The tests passed.

Decision or revision: Collection is implemented through the mutable
`World.collect_lambda` operation. The world removes the lambda in place, so
all later observations see the collected state.

## Task 4: Sandworm moves deterministically toward the camel

Planned behavior: After every successful move or wait that does not end the
game, the sandworm should move to the legal neighboring cell with minimum
Manhattan distance to the camel. Ties should be resolved in north, east,
south, west order. The sandworm must not enter walls, the exit, or cells
outside the map. If it has no legal neighbor, it should stay in place.

Planned check: Test a tie, blocked neighboring cells, an exit that blocks a
candidate, a fully boxed-in sandworm, and a blocked camel move. The expected
result is deterministic movement according to the stated order, with no
movement when no legal move exists.

Actual check and result: The OUnit tests `sandworm tie breaks north first`,
`sandworm skips walls and exit`, `boxed-in sandworm does not move`, and `game
blocked move` cover these cases. The sandworm chooses the north candidate on
a tie, skips walls and the exit, remains boxed in when appropriate, and does
not move after a blocked camel action. The tests passed.

Decision or revision: Candidate positions are constructed in north, east,
south, west order and selected with a strict distance comparison. Keeping the
first candidate on equal distance implements the required tie-breaking rule.

## Task 5: Turn order, exit behavior, and game outcomes

Planned behavior: A legal move or wait should increment the turn count and
reveal the camel's neighborhood. Collision with the sandworm should cause
defeat before lambda collection. Otherwise, collection should occur, followed
by victory if the camel is on the exit with at least 8 points. If the game
does not end, the sandworm should move. No actions should be accepted after
the game ends.

Planned check: Test entering the exit with fewer than 8 points, reaching the
exit with at least 8 points, collision before collection, collision caused by
the sandworm after a wait, and an action after victory.

Actual check and result: The OUnit tests `exit requires eight points`, `victory
stops the game`, `collision prevents collection`, and `sandworm collision after
wait` cover these transitions. The exit remains traversable with 7 points,
8 points produces victory, a collision leaves a lambda uncollected, a
sandworm collision produces defeat, and a move after victory does not change
the game. The tests passed.

Decision or revision: The action order is implemented explicitly in
`Game.act`: camel update, reveal, collision check, collection, victory check,
and then sandworm movement. This matches the assignment's required turn
ordering.

## Task 6: Seeded generation is reproducible and valid

Planned behavior: A nonnegative seed should deterministically produce a
bounded labyrinth with multiple rooms, varied terrain, distinct actor
placements, reachable paths, and enough reachable lambda points to escape.

Planned check: For seeds 0 through 20, generate each map twice and check
dimensions, reproducibility, distinct placements, Manhattan-distance
requirements, paths, lambda uniqueness and reachability, and a total lambda
value of at least 8. Also compare terrain from different seeds.

Actual check and result: The OUnit tests `same seed`, `generated dimensions`,
`generated positions`, `generated lambdas`, `generated paths`, and `generated
terrain varies` perform these checks. The generated maps are reproducible,
fit within 20 rows by 70 columns, contain valid distinct placements, have
the required paths, and contain at least 8 reachable lambda points. Terrain
variation is checked after treating the exit as floor, so the test observes
wall-layout variation rather than only a changed exit location. The tests
passed for all listed seeds.

Decision or revision: Initial lambda placement was probabilistic and could
fail to provide enough points. The generator now finds reachable cells first,
places guaranteed gold and silver lambdas for 8 points, and adds optional
copper lambdas afterward. The generator also selects the exit separately from
the sandworm and adds seed-dependent wall variation while preserving the
connected corridor structure.

## Task 7: Play the full game in the terminal with immediate input

Planned behavior: `dune exec a3 -- <seed>` should start the game, accept keys
without requiring Return, redraw the map in place, show the seed, score,
required score, turn count, and controls, and restore terminal settings after
quitting. Invalid seeds should produce helpful errors.

Planned check: Run the executable with a fixed seed in a real terminal. Press
movement, wait, unknown, and quit keys. Confirm immediate input, in-place
redrawing, correct turn behavior, and restored terminal echo. Run with
`abc` and `-5` to check invalid-seed handling.

Actual check and result: The game was run with `dune exec a3 -- 42` in a real
terminal. The map redraws in place using ANSI clear-screen and cursor-home
sequences. The interface displays the seed, score, required score, turns, and
controls. Movement and wait keys are processed immediately, unknown keys do
not perform an action, and `q` quits. The commands
`dune exec a3 -- abc` and `dune exec a3 -- -5` both produce an error message
and usage text instead of crashing. The checks passed.

Decision or revision: Terminal setup and restoration are isolated in
`with_raw_terminal` so terminal settings are restored even when the game
loop exits.

## Validation Summary (R5.2)

The library behavior is validated by an OUnit suite runnable with `dune test`.
The suite covers direct map construction, terrain and lambda access, seeded
reproducibility, dimensions, actor placement, reachable paths, terrain
variation, lambda guarantees, movement, waiting, fog of war, collection,
sandworm movement, collisions, exit behavior, victory, defeat, and ignoring
actions after the game ends.

The generated-map properties are checked across seeds 0 through 20. The
interactive interface was also checked manually in a real terminal with seed
42, including immediate input, in-place redrawing, quitting, and invalid
seed errors.

Final automated validation:

```text
dune build
dune test
Ran: 24 tests
OK
```
