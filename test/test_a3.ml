open OUnit2
open A3
open World

let make_position row col = { row; col }

let hand_built_world () =
  from_setup
    {
      grid =
        [|
          [| Wall; Wall; Wall; Wall; Wall |];
          [| Wall; Floor; Floor; Floor; Wall |];
          [| Wall; Floor; Exit; Floor; Wall |];
          [| Wall; Wall; Wall; Wall; Wall |];
        |];
      camel = make_position 1 1;
      sandworm = make_position 1 3;
      exit = make_position 2 2;
      lambdas = [ (make_position 1 2, Silver) ];
    }

let test_dimensions _ =
  let world = hand_built_world () in
  assert_equal 4 (rows world);
  assert_equal 5 (cols world)

let test_terrain_and_lambda_lookup _ =
  let world = hand_built_world () in
  assert_equal Wall (terrain_at world (make_position 0 0));
  assert_equal Floor (terrain_at world (make_position 1 1));
  assert_equal Exit (terrain_at world (make_position 2 2));
  assert_equal (Some Silver) (lambda_at world (make_position 1 2));
  assert_equal None (lambda_at world (make_position 1 1))

let test_actor_positions _ =
  let world = hand_built_world () in
  assert_equal (make_position 1 1) (camel_position world);
  assert_equal (make_position 1 3) (sandworm_position world);
  assert_equal (make_position 2 2) (exit_position world)

let test_lambdas _ =
  let world = hand_built_world () in
  assert_equal [ (make_position 1 2, Silver) ] (lambdas world)

let generated_snapshot seed =
  let world = generate seed in
  ( rows world,
    cols world,
    Array.init (rows world) (fun row ->
        Array.init (cols world) (fun col ->
            terrain_at world (make_position row col))),
    lambdas world,
    camel_position world,
    sandworm_position world,
    exit_position world )

let test_same_seed _ =
  assert_equal (generated_snapshot 3110) (generated_snapshot 3110)

let test_different_seeds _ =
  assert_bool
    "different seeds should produce different worlds"
    (generated_snapshot 1 <> generated_snapshot 2)

let manhattan first second =
  abs (first.row - second.row) + abs (first.col - second.col)

let neighbors position =
  [
    position.row - 1, position.col;
    position.row, position.col + 1;
    position.row + 1, position.col;
    position.row, position.col - 1;
  ]
  |> List.map (fun (row, col) -> make_position row col)

let reachable world ~start ~goal ~avoid_exit =
  let rec search visited = function
    | [] -> false
    | current :: rest ->
        if current = goal then true
        else if List.mem current visited then search visited rest
        else
          let visited = current :: visited in
          let next =
            neighbors current
            |> List.filter (fun position ->
                 position.row >= 0
                 && position.row < rows world
                 && position.col >= 0
                 && position.col < cols world)
            |> List.filter (fun position ->
                 terrain_at world position <> Wall)
            |> List.filter (fun position ->
                 not avoid_exit || position <> exit_position world)
          in
          search visited (List.rev_append next rest)
  in
  search [] [ start ]

let lambda_value = function
  | Copper -> 1
  | Silver -> 3
  | Gold -> 5

let test_generated_dimensions _ =
  List.iter
    (fun seed ->
      let world = generate seed in
      assert_bool "rows must be positive" (rows world > 0);
      assert_bool "columns must be positive" (cols world > 0);
      assert_bool "rows must be at most 20" (rows world <= 20);
      assert_bool "columns must be at most 70" (cols world <= 70))
    (List.init 21 Fun.id)

let test_generated_positions _ =
  List.iter
    (fun seed ->
      let world = generate seed in
      let camel = camel_position world in
      let sandworm = sandworm_position world in
      let exit = exit_position world in
      assert_bool "actors must be distinct" (camel <> sandworm);
      assert_bool "camel and exit must be distinct" (camel <> exit);
      assert_bool "sandworm and exit must be distinct" (sandworm <> exit);
      assert_equal Floor (terrain_at world camel);
      assert_equal Floor (terrain_at world sandworm);
      assert_equal Exit (terrain_at world exit);
      assert_bool "camel must be far from sandworm"
        (manhattan camel sandworm >= 6);
      assert_bool "camel must be far from exit" (manhattan camel exit >= 6))
    (List.init 21 Fun.id)

let test_generated_lambdas _ =
  List.iter
    (fun seed ->
      let world = generate seed in
      let positions = List.map fst (lambdas world) in
      let values = List.map (fun (_, lambda) -> lambda_value lambda) (lambdas world) in
      assert_bool "lambdas must be distinct"
        (List.length positions = List.length (List.sort_uniq compare positions));
      assert_bool "lambdas must be worth at least eight points"
        (List.fold_left ( + ) 0 values >= 8);
      List.iter
        (fun position ->
          assert_bool "lambda must not be on a wall"
            (terrain_at world position <> Wall);
          assert_bool "lambda must be reachable from camel"
            (reachable world ~start:(camel_position world) ~goal:position
               ~avoid_exit:false))
        positions)
    (List.init 21 Fun.id)

let test_generated_paths _ =
  List.iter
    (fun seed ->
      let world = generate seed in
      assert_bool "camel must reach exit"
        (reachable world ~start:(camel_position world)
           ~goal:(exit_position world) ~avoid_exit:false);
      assert_bool "sandworm must reach camel without crossing exit"
        (reachable world ~start:(sandworm_position world)
           ~goal:(camel_position world) ~avoid_exit:true))
    (List.init 21 Fun.id)

let test_generated_terrain_varies _ =
  let first = generated_snapshot 0 in
  let terrain_of_snapshot (_, _, terrain, _, _, _, _) =
    Array.map
      (Array.map (function
        | Exit -> Floor
        | terrain -> terrain))
      terrain
  in
  assert_bool "terrain should vary across seeds"
    (List.init 20 (fun index -> index + 1)
     |> List.exists (fun seed ->
            terrain_of_snapshot (generated_snapshot seed)
            <> terrain_of_snapshot first))

let game_world () =
  let grid =
    Array.init 7 (fun row ->
        Array.init 7 (fun col ->
            if row = 0 || row = 6 || col = 0 || col = 6 then Wall else Floor))
  in
  grid.(5).(5) <- Exit;
  from_setup
    {
      grid;
      camel = make_position 3 1;
      sandworm = make_position 1 5;
      exit = make_position 5 5;
      lambdas = [ (make_position 3 2, Silver) ];
    }

let test_game_initial_reveal _ =
  let game = Game.of_world (game_world ()) in
  assert_bool "camel is initially revealed"
    (Game.is_revealed game (make_position 3 1));
  assert_bool "north neighbor is initially revealed"
    (Game.is_revealed game (make_position 2 1));
  assert_bool "east neighbor is initially revealed"
    (Game.is_revealed game (make_position 3 2));
  assert_bool "distant cell remains hidden"
    (not (Game.is_revealed game (make_position 1 1)))

let boxed_game ~camel ~sandworm ~exit ~lambdas ~extra_walls =
  let grid =
    Array.init 5 (fun row ->
        Array.init 5 (fun col ->
            if row = 0 || row = 4 || col = 0 || col = 4 then Wall
            else Floor))
  in
  List.iter
    (fun position -> grid.(position.row).(position.col) <- Wall)
    extra_walls;
  grid.(exit.row).(exit.col) <- Exit;
  Game.of_world
    (from_setup { grid; camel; sandworm; exit; lambdas })

let test_fog_stops_at_wall _ =
  let game =
    boxed_game ~camel:(make_position 2 1) ~sandworm:(make_position 3 3)
      ~exit:(make_position 3 2) ~lambdas:[]
      ~extra_walls:[ make_position 2 2 ]
  in
  assert_bool "wall adjacent to camel is revealed"
    (Game.is_revealed game (make_position 2 2));
  assert_bool "cell beyond wall remains hidden"
    (not (Game.is_revealed game (make_position 2 3)))

let test_game_blocked_move _ =
  let game = Game.of_world (game_world ()) in
  Game.act game (Game.Move Game.West);
  assert_equal (make_position 3 1) (Game.camel_position game);
  assert_equal 0 (Game.turns game);
  assert_equal (make_position 1 5) (Game.sandworm_position game);
  assert_equal Game.Playing (Game.outcome game)

let test_game_collects_lambda _ =
  let game = Game.of_world (game_world ()) in
  Game.act game (Game.Move Game.East);
  assert_equal (make_position 3 2) (Game.camel_position game);
  assert_equal 3 (Game.score game);
  assert_equal None
    (lambda_at (Game.world game) (make_position 3 2));
  assert_equal 1 (Game.turns game)

let test_game_collects_lambda_once _ =
  let game = Game.of_world (game_world ()) in
  Game.act game (Game.Move Game.East);
  Game.act game (Game.Move Game.West);
  Game.act game (Game.Move Game.East);
  assert_equal 3 (Game.score game);
  assert_equal 3 (Game.turns game)

let test_game_wait _ =
  let game = Game.of_world (game_world ()) in
  Game.act game Game.Wait;
  assert_equal 1 (Game.turns game);
  assert_equal (make_position 3 1) (Game.camel_position game);
  assert_equal Game.Playing (Game.outcome game)

let test_sandworm_tie_breaks_north_first _ =
  let game =
    boxed_game ~camel:(make_position 1 1) ~sandworm:(make_position 2 2)
      ~exit:(make_position 3 3) ~lambdas:[] ~extra_walls:[]
  in
  Game.act game Game.Wait;
  assert_equal (make_position 1 2) (Game.sandworm_position game)

let test_sandworm_skips_walls_and_exit _ =
  let game =
    boxed_game ~camel:(make_position 1 1) ~sandworm:(make_position 2 2)
      ~exit:(make_position 3 2) ~lambdas:[]
      ~extra_walls:[ make_position 1 2; make_position 2 1 ]
  in
  Game.act game Game.Wait;
  assert_equal (make_position 2 3) (Game.sandworm_position game)

let test_boxed_in_sandworm_does_not_move _ =
  let game =
    boxed_game ~camel:(make_position 1 1) ~sandworm:(make_position 2 2)
      ~exit:(make_position 3 3) ~lambdas:[]
      ~extra_walls:
        [
          make_position 1 2;
          make_position 2 1;
          make_position 2 3;
          make_position 3 2;
        ]
  in
  Game.act game Game.Wait;
  assert_equal (make_position 2 2) (Game.sandworm_position game)

let test_exit_requires_eight_points _ =
  let game =
    boxed_game ~camel:(make_position 2 1) ~sandworm:(make_position 3 3)
      ~exit:(make_position 2 3)
      ~lambdas:
        [
          (make_position 1 1, Gold);
          (make_position 1 2, Copper);
          (make_position 1 3, Copper);
        ]
      ~extra_walls:[ make_position 3 2; make_position 3 1 ]
  in
  List.iter
    (Game.act game)
    [ Game.Move Game.North; Game.Move Game.East; Game.Move Game.East;
      Game.Move Game.South ];
  assert_equal 7 (Game.score game);
  assert_equal Game.Playing (Game.outcome game)

let test_victory_stops_the_game _ =
  let game =
    boxed_game ~camel:(make_position 2 1) ~sandworm:(make_position 3 3)
      ~exit:(make_position 2 3)
      ~lambdas:
        [ (make_position 1 1, Gold); (make_position 1 2, Silver) ]
      ~extra_walls:[ make_position 3 2; make_position 3 1 ]
  in
  List.iter
    (Game.act game)
    [ Game.Move Game.North; Game.Move Game.East; Game.Move Game.East;
      Game.Move Game.South ];
  assert_equal 8 (Game.score game);
  assert_equal Game.Victory (Game.outcome game);
  let turns = Game.turns game in
  Game.act game (Game.Move Game.West);
  assert_equal turns (Game.turns game);
  assert_equal (make_position 2 3) (Game.camel_position game)

let test_collision_prevents_collection _ =
  let game =
    boxed_game ~camel:(make_position 2 1) ~sandworm:(make_position 2 2)
      ~exit:(make_position 3 3) ~lambdas:[ (make_position 2 2, Gold) ]
      ~extra_walls:[ make_position 3 2; make_position 3 1 ]
  in
  Game.act game (Game.Move Game.East);
  assert_equal Game.Defeat (Game.outcome game);
  assert_equal 0 (Game.score game);
  assert_equal (Some Gold)
    (lambda_at (Game.world game) (make_position 2 2))

let test_sandworm_collision_after_wait _ =
  let game =
    boxed_game ~camel:(make_position 2 2) ~sandworm:(make_position 2 3)
      ~exit:(make_position 3 3) ~lambdas:[] ~extra_walls:[]
  in
  Game.act game Game.Wait;
  assert_equal Game.Defeat (Game.outcome game);
  assert_equal (make_position 2 2) (Game.sandworm_position game)

let suite =
  "a3"
  >::: [
         "dimensions" >:: test_dimensions;
         "terrain and lambda lookup" >:: test_terrain_and_lambda_lookup;
         "actor positions" >:: test_actor_positions;
         "lambdas" >:: test_lambdas;
         "same seed" >:: test_same_seed;
         "different seeds" >:: test_different_seeds;
         "generated dimensions" >:: test_generated_dimensions;
         "generated positions" >:: test_generated_positions;
         "generated lambdas" >:: test_generated_lambdas;
         "generated paths" >:: test_generated_paths;
         "generated terrain varies" >:: test_generated_terrain_varies;
         "game initial reveal" >:: test_game_initial_reveal;
         "fog stops at wall" >:: test_fog_stops_at_wall;
         "game blocked move" >:: test_game_blocked_move;
         "game collects lambda" >:: test_game_collects_lambda;
         "game collects lambda once" >:: test_game_collects_lambda_once;
         "game wait" >:: test_game_wait;
         "sandworm tie breaks north first" >:: test_sandworm_tie_breaks_north_first;
         "sandworm skips walls and exit" >:: test_sandworm_skips_walls_and_exit;
         "boxed-in sandworm does not move" >:: test_boxed_in_sandworm_does_not_move;
         "exit requires eight points" >:: test_exit_requires_eight_points;
         "victory stops the game" >:: test_victory_stops_the_game;
         "collision prevents collection" >:: test_collision_prevents_collection;
         "sandworm collision after wait" >:: test_sandworm_collision_after_wait;
       ]

let () = run_test_tt_main suite
