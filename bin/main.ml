open A3

(** [usage ()] prints command-line usage information and exits with an error. *)
let usage () =
  Printf.eprintf "Usage: dune exec a3 -- [nonnegative-seed]\n";
  exit 1

(** [seed_from_args ()] parses a nonnegative seed or generates one when omitted. *)
let seed_from_args () =
  match Array.length Sys.argv with
  | 1 ->
      Random.self_init ();
      Random.int 1_000_000_000
  | 2 -> (
      try
        let seed = int_of_string Sys.argv.(1) in
        if seed < 0 then raise (Invalid_argument "negative seed");
        seed
      with
      | Failure _ | Invalid_argument _ ->
          Printf.eprintf "Invalid seed: %s\n" Sys.argv.(1);
          usage ())
  | _ -> usage ()

(** [lambda_symbol lambda] is the display character for [lambda]. *)
let lambda_symbol = function
  | World.Copper -> 'c'
  | World.Silver -> 's'
  | World.Gold -> 'g'

(** [terrain_symbol world position] is the display character for a revealed
    cell at [position]. *)
let terrain_symbol world position =
  match World.lambda_at world position with
  | Some lambda -> lambda_symbol lambda
  | None -> (
      match World.terrain_at world position with
      | World.Wall -> '#'
      | World.Floor -> '.'
      | World.Exit -> '>')

(** [symbol_at game position] is the display character for [position] in
    [game]. *)
let symbol_at game position =
  let world = Game.world game in
  let camel = Game.camel_position game in
  let sandworm = Game.sandworm_position game in
  match Game.outcome game with
  | Game.Defeat when position = camel && position = sandworm -> 'X'
  | Game.Victory when position = camel -> '^'
  | _ when position = camel -> 'C'
  | _ when position = sandworm -> 'W'
  | _ when not (Game.is_revealed game position) -> '?'
  | _ -> terrain_symbol world position

(** [render seed game] redraws the current game state in the terminal. *)
let render seed game =
  let world = Game.world game in
  print_string "\027[2J\027[H";
  Printf.printf "Seed: %d  Score: %d/8  Turns: %d\n" seed
    (Game.score game) (Game.turns game);
  Printf.printf "Controls: w/a/s/d move, . wait, q quit\n\n";
  for row = 0 to World.rows world - 1 do
    for col = 0 to World.cols world - 1 do
      Printf.printf "%c" (symbol_at game { World.row; col })
    done;
    print_newline ()
  done;
  (match Game.outcome game with
  | Game.Playing -> ()
  | Game.Victory -> print_endline "\nVictory! You escaped the labyrinth."
  | Game.Defeat -> print_endline "\nDefeat! The sandworm caught the camel."
  | Game.Quit -> print_endline "\nYou quit the game.");
  flush stdout

(** [action_of_char character] translates an input key into a game action. *)
let action_of_char = function
  | 'w' -> Some (Game.Move Game.North)
  | 'a' -> Some (Game.Move Game.West)
  | 's' -> Some (Game.Move Game.South)
  | 'd' -> Some (Game.Move Game.East)
  | '.' -> Some Game.Wait
  | 'q' -> Some Game.Quit
  | _ -> None

(** [with_raw_terminal f] runs [f] with immediate terminal input and restores
    the original terminal settings afterward. *)
let with_raw_terminal f =
  let original = Unix.tcgetattr Unix.stdin in
  let raw = { original with Unix.c_icanon = false; c_echo = false; c_vmin = 1; c_vtime = 0 } in
  Unix.tcsetattr Unix.stdin Unix.TCSANOW raw;
  Fun.protect
    ~finally:(fun () -> Unix.tcsetattr Unix.stdin Unix.TCSANOW original)
    f

(** [play seed] runs the interactive game loop for [seed]. *)
let play seed =
  let game = Game.create ~seed in
  let rec loop () =
    render seed game;
    if Game.outcome game = Game.Playing then (
      let key = input_char stdin in
      match action_of_char key with
      | None -> loop ()
      | Some action ->
          Game.act game action;
          loop ())
  in
  with_raw_terminal loop

let () =
  let seed = seed_from_args () in
  try play seed with
  | Unix.Unix_error (error, function_name, argument) ->
      Printf.eprintf "Terminal error in %s(%s): %s\n" function_name argument
        (Unix.error_message error);
      exit 1
