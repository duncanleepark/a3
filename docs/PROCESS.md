# Development Record

## Task 1: Move around a tiny hand-built world and see the updated position

Planned behavior: Build a small map from explicit data (no seed, no generator), place the camel, apply w/a/s/d, and print the grid in the terminal. The camel moves one cell per legal key; moving into a wall or off the map changes nothing (including the turn count).

Planned check: On a 3x3 world with walls on the right column and the camel at the center, apply `d`, `w`, `a`. Expected: `d` is blocked (position and turns unchanged), `w` moves up (turns = 1), `a` moves left (turns = 2). Also apply `.` and confirm the position is unchanged but turns increases by one.

Actual check and result: [What I ran (OUnit test name or manual run), what I observed, whether it matched.]

Decision or revision: [What the evidence led me to change or keep, and why.]

## Task 2: Fog of war reveals a cross and stays revealed

Planned behavior: Rendering shows `?` for undiscovered cells. Before the first input the camel's cell and its in-bounds orthogonal neighbors are revealed; each successful move reveals the same cross at the new position. Revealed cells stay revealed.

Planned check: On a 5x5 world with the camel in a corner, check that exactly 3 cells are revealed initially (camel plus two in-bounds neighbors). Move one step and check that the new cross is added, old cells remain revealed, and a wall adjacent to the camel is revealed but the cell beyond it is not. Also check that the sandworm is displayed while still in fog, without revealing its cell's terrain.

Actual check and result: [...]

Decision or revision: [...]

## Task 3: Collect a lambda once and track the score

Planned behavior: Entering a lambda cell adds its value (copper 1, silver 3, gold 5) to the score and removes it permanently from the map.

Planned check: Put a silver lambda directly right of the camel. Move `d`, then `a`, then `d` again. Expected: score is 3 after the first visit and stays 3 after revisiting; the cell displays as `.` afterward.

Actual check and result: [...]

Decision or revision: [...]

## Task 4: Sandworm moves deterministically toward the camel

Planned behavior: After each successful move or wait that has not ended the game, the sandworm moves one step to the legal neighbor with minimum Manhattan distance to the camel, breaking ties in N, E, S, W order. It cannot enter walls, the exit, or out-of-bounds cells, and it does not move if no legal neighbor exists. It may move through lambdas without collecting them.

Planned check: Three tiny scenarios: (a) a tie between two neighbors, expecting the north-first choice; (b) the best neighbor is a wall or the exit, expecting the next-best legal neighbor (even if farther than the current cell); (c) a fully boxed-in sandworm, expecting no movement. Also check that a blocked camel move does not move the sandworm.

Actual check and result: [...]

Decision or revision: [...]

## Task 5: Turn order, exit behavior, and game outcomes

Planned behavior: Turn order follows R2: increment turns, move the camel, reveal; defeat if on the sandworm's cell (no lambda collected); otherwise collect; victory if on the exit with at least 8 points; otherwise move the sandworm and check defeat. No actions are accepted after the game ends.

Planned check: (a) Camel steps onto the exit with 7 points: the game continues and the exit acts as floor. (b) Camel steps onto the exit with 8 points: victory, shown as `^`, and further keys do nothing. (c) Camel steps onto the sandworm's cell that holds a lambda: defeat, score unchanged, shown as `X`. (d) The sandworm steps onto the camel after a wait: defeat.

Actual check and result: [...]

Decision or revision: [...]

## Task 6: Seeded generation is reproducible and valid

Planned behavior: A seed deterministically produces a labyrinth of multiple rooms, at most 20 rows by 70 columns, with the camel, sandworm, exit, and lambdas placed per R1.3. Different seeds produce visibly different terrain.

Planned check: For seeds 0 through ~20, generate twice and check that the two maps are identical. Check that: the camel, sandworm, and exit are on distinct floor cells; the exit and sandworm are at Manhattan distance of at least 6 from the camel; the camel can reach the exit; the sandworm can reach the camel without crossing the exit; there are multiple lambdas on distinct reachable floor cells worth at least 8 points in total; and at least two seeds give different terrain. Manually print two seeds to look at them.

Actual check and result: [...]

Decision or revision: [...]

## Task 7: Play the full game in the terminal with immediate input

Planned behavior: `dune exec` with a seed argument (or an interactive prompt) starts the game. Keys are read without pressing Return, the map is redrawn in place, and the display shows the seed, score, required score, turn count, and a controls legend. `q` quits and terminal settings are restored. An invalid seed gives a helpful error.

Planned check: Run with seed 42, press `d`/`s` and confirm the screen redraws immediately, press an unrecognized key and confirm nothing changes, then press `q` and confirm the terminal echoes typed characters normally again. Run with seed `abc` and with `-5` and confirm an error message rather than a crash.

Actual check and result: [...]

Decision or revision: [...]

## Validation Summary (R5.2)

[Brief note on how each completed task was validated: which OUnit tests cover it, which checks were manual, and why the expected results follow from the rules in the handout.]