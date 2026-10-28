open World

type direction =
  | North
  | East
  | South
  | West

type action =
  | Move of direction
  | Wait
  | Quit

type outcome =
  | Playing
  | Victory
  | Defeat
  | Quit

type t = {
  world : World.world;
  mutable camel : World.position;
  mutable sandworm : World.position;
  mutable score : int;
  mutable turns : int;
  mutable outcome : outcome;
  revealed : bool array array;
}

let of_world world =
  let game =
    {
      world;
      camel = World.camel_position world;
      sandworm = World.sandworm_position world;
      score = 0;
      turns = 0;
      outcome = Playing;
      revealed =
        Array.make_matrix (World.rows world) (World.cols world) false;
    }
  in
  let position = game.camel in
  game.revealed.(position.row).(position.col) <- true;
  List.iter
    (fun (row, col) ->
      if row >= 0 && row < World.rows world && col >= 0 && col < World.cols world
      then game.revealed.(row).(col) <- true)
    [
      position.row - 1, position.col;
      position.row, position.col + 1;
      position.row + 1, position.col;
      position.row, position.col - 1;
    ];
  game

let create ~seed =
  of_world (World.generate seed)

let world game = game.world
let camel_position game = game.camel
let sandworm_position game = game.sandworm
let score game = game.score
let turns game = game.turns
let outcome game = game.outcome

let in_bounds game position =
  position.row >= 0
  && position.row < World.rows game.world
  && position.col >= 0
  && position.col < World.cols game.world

let is_revealed game position =
  in_bounds game position && game.revealed.(position.row).(position.col)

let reveal game position =
  if in_bounds game position then game.revealed.(position.row).(position.col) <- true

let reveal_cross game position =
  reveal game position;
  List.iter
    (fun (row, col) -> reveal game { World.row = row; col })
    [
      position.row - 1, position.col;
      position.row, position.col + 1;
      position.row + 1, position.col;
      position.row, position.col - 1;
    ]

let move_position position = function
  | North -> { World.row = position.row - 1; col = position.col }
  | East -> { World.row = position.row; col = position.col + 1 }
  | South -> { World.row = position.row + 1; col = position.col }
  | West -> { World.row = position.row; col = position.col - 1 }

let passable game position =
  in_bounds game position && World.terrain_at game.world position <> Wall

let lambda_value = function
  | World.Copper -> 1
  | World.Silver -> 3
  | World.Gold -> 5

let collect game =
  match World.collect_lambda game.world game.camel with
  | None -> ()
  | Some lambda -> game.score <- game.score + lambda_value lambda

let defeat_if_colliding game =
  if game.camel = game.sandworm then game.outcome <- Defeat

let sandworm_step game =
  let candidates =
    [
      North, move_position game.sandworm North;
      East, move_position game.sandworm East;
      South, move_position game.sandworm South;
      West, move_position game.sandworm West;
    ]
    |> List.filter (fun (_, position) -> passable game position)
    |> List.filter (fun (_, position) ->
         position <> World.exit_position game.world)
  in
  match candidates with
  | [] -> ()
  | (_, first_position) :: rest ->
      let distance position =
        abs (position.row - game.camel.row)
        + abs (position.col - game.camel.col)
      in
      let best_position, _ =
        List.fold_left
          (fun (best_position, best_distance) (_, position) ->
            let candidate_distance = distance position in
            if candidate_distance < best_distance then
              position, candidate_distance
            else best_position, best_distance)
          (first_position, distance first_position)
          rest
      in
      game.sandworm <- best_position;
      defeat_if_colliding game

let act game (action : action) =
  match action with
  | Quit ->
      if game.outcome = Playing then game.outcome <- Quit
  | _ when game.outcome <> Playing -> ()
  | Wait ->
      game.turns <- game.turns + 1;
      reveal_cross game game.camel;
      sandworm_step game
  | Move direction ->
      let destination = move_position game.camel direction in
      if passable game destination then (
        game.turns <- game.turns + 1;
        game.camel <- destination;
        reveal_cross game game.camel;
        defeat_if_colliding game;
        if game.outcome = Playing then (
          collect game;
          if
            game.camel = World.exit_position game.world
            && game.score >= 8
          then game.outcome <- Victory
          else sandworm_step game))