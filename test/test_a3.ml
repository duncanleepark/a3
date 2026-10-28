open OUnit2
open A3
open World

let position row col = { row; col }

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
      camel = position 1 1;
      sandworm = position 1 3;
      exit = position 2 2;
      lambdas = [ (position 1 2, Silver) ];
    }

let test_dimensions _ =
  let world = hand_built_world () in
  assert_equal 4 (rows world);
  assert_equal 5 (cols world)

let test_terrain_and_lambda_lookup _ =
  let world = hand_built_world () in
  assert_equal Wall (terrain_at world (position 0 0));
  assert_equal Floor (terrain_at world (position 1 1));
  assert_equal Exit (terrain_at world (position 2 2));
  assert_equal (Some Silver) (lambda_at world (position 1 2));
  assert_equal None (lambda_at world (position 1 1))

let test_actor_positions _ =
  let world = hand_built_world () in
  assert_equal (position 1 1) (camel_position world);
  assert_equal (position 1 3) (sandworm_position world);
  assert_equal (position 2 2) (exit_position world)

let test_lambdas _ =
  let world = hand_built_world () in
  assert_equal [ (position 1 2, Silver) ] (lambdas world)

let generated_snapshot seed =
  let world = generate seed in
  ( rows world,
    cols world,
    Array.init (rows world) (fun row ->
        Array.init (cols world) (fun col ->
            terrain_at world (position row col))),
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

let suite =
  "a3"
  >::: [
         "dimensions" >:: test_dimensions;
         "terrain and lambda lookup" >:: test_terrain_and_lambda_lookup;
         "actor positions" >:: test_actor_positions;
         "lambdas" >:: test_lambdas;
         "same seed" >:: test_same_seed;
         "different seeds" >:: test_different_seeds;
       ]

let () = run_test_tt_main suite
