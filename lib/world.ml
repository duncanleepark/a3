type terrain =
  | Wall
  | Floor
  | Exit

type lambda =
  | Copper
  | Silver
  | Gold

type position = {
  row : int;
  col : int;
}

type setup = {
  grid : terrain array array;
  camel : position;
  sandworm : position;
  exit : position;
  lambdas : (position * lambda) list;
}

type cell = {
  terrain : terrain;
  mutable lambda : lambda option;
}

type world = {
  grid : cell array array;
  camel : position;
  sandworm : position;
  exit : position;
}

(** [rows world] is the number of rows in the world grid. *)
let rows world =
  Array.length world.grid

(** [cols world] is the number of columns in the world grid. *)
let cols world =
  if rows world = 0 then 0 else Array.length world.grid.(0)

(** [in_bounds grid position] is [true] when [position] lies in [grid]. *)
let in_bounds grid position =
  position.row >= 0
  && position.row < Array.length grid
  && position.col >= 0
  && position.col < Array.length grid.(position.row)

(** [from_setup setup] constructs a world from explicit terrain and contents. *)
let from_setup (setup : setup) =
  if Array.length setup.grid = 0 then invalid_arg "World.from_setup: empty grid";
  let grid =
    Array.map
      (fun row ->
        if Array.length row = 0 then invalid_arg "World.from_setup: empty row";
        Array.map (fun terrain -> { terrain; lambda = None }) row)
      setup.grid
  in
  if
    not (in_bounds setup.grid setup.camel)
    || not (in_bounds setup.grid setup.sandworm)
    || not (in_bounds setup.grid setup.exit)
  then invalid_arg "World.from_setup: position out of bounds";
  List.iter
    (fun (position, lambda) ->
      if not (in_bounds setup.grid position) then
        invalid_arg "World.from_setup: lambda out of bounds";
      if grid.(position.row).(position.col).terrain = Wall then
        invalid_arg "World.from_setup: lambda on wall";
      if grid.(position.row).(position.col).lambda <> None then
        invalid_arg "World.from_setup: duplicate lambda";
      grid.(position.row).(position.col).lambda <- Some lambda)
    setup.lambdas;
  {
    grid;
    camel = setup.camel;
    sandworm = setup.sandworm;
    exit = setup.exit;
  }

(** [terrain_at world position] is the terrain at [position]. *)
let terrain_at world position =
  world.grid.(position.row).(position.col).terrain

(** [lambda_at world position] is the lambda at [position], if present. *)
let lambda_at world position =
  world.grid.(position.row).(position.col).lambda

(** [collect_lambda world position] removes and returns the lambda at [position]. *)
let collect_lambda world position =
  let cell = world.grid.(position.row).(position.col) in
  let collected = cell.lambda in
  cell.lambda <- None;
  collected

(** [camel_position world] is the initial camel position. *)
let camel_position world = world.camel
(** [sandworm_position world] is the initial sandworm position. *)
let sandworm_position world = world.sandworm
(** [exit_position world] is the exit position. *)
let exit_position world = world.exit

(** [lambdas world] is the list of lambdas that remain in [world]. *)
let lambdas world =
  let result = ref [] in
  Array.iteri
    (fun row cells ->
      Array.iteri
        (fun col cell ->
          match cell.lambda with
          | None -> ()
          | Some lambda -> result := ({ row; col }, lambda) :: !result)
        cells)
    world.grid;
  List.rev !result

(** [from_grid grid] constructs a test world using the first three open cells
    for the camel, sandworm, and exit. *)
let from_grid grid =
  let positions = ref [] in
  Array.iteri
    (fun row cells ->
      Array.iteri
        (fun col terrain ->
          if terrain <> Wall then positions := { row; col } :: !positions)
        cells)
    grid;
  match List.rev !positions with
  | camel :: sandworm :: exit :: _ ->
      from_setup { grid; camel; sandworm; exit; lambdas = [] }
  | _ -> invalid_arg "World.from_grid: need at least three non-wall cells"

(** [generate seed] creates a deterministic, connected labyrinth from [seed]. *)
let generate seed =
  let random = Random.State.make [| seed |] in
  let row_count = 15 in
  let col_count = 45 in
  let grid = Array.make_matrix row_count col_count Wall in
  (** [carve row col] turns an in-bounds interior cell into floor. *)
  let carve row col =
    if row > 0 && row < row_count - 1 && col > 0 && col < col_count - 1
    then grid.(row).(col) <- Floor
  in
  for row = 1 to row_count - 2 do
    for col = 1 to col_count - 2 do
      carve row col
    done
  done;
  for col = 1 to col_count - 2 do
    if col <> 7 && col <> 23 && col <> 37 then grid.(4).(col) <- Wall;
    if col <> 12 && col <> 30 && col <> 41 then grid.(9).(col) <- Wall
  done;
  for row = 1 to row_count - 2 do
    if row <> 2 && row <> 7 && row <> 12 then grid.(row).(15) <- Wall;
    if row <> 5 && row <> 11 then grid.(row).(30) <- Wall
  done;
  let varied_wall_column = 2 + Random.State.int random 12 in
  grid.(2).(varied_wall_column) <- Wall;
  let floors = ref [] in
  Array.iteri
    (fun row cells ->
      Array.iteri
        (fun col terrain ->
          if terrain = Floor then floors := { row; col } :: !floors)
        cells)
    grid;
  let floors = Array.of_list !floors in
  (** [choose_far position] selects a random floor cell at least six steps
      from [position] and not in the optional exclusion list. *)
  let choose_far ?(excluded = []) position =
    let candidates =
      Array.to_list floors
      |> List.filter (fun other ->
           abs (position.row - other.row) + abs (position.col - other.col) >= 6)
      |> List.filter (fun other -> not (List.mem other excluded))
    in
    List.nth candidates (Random.State.int random (List.length candidates))
  in
  let camel = floors.(Random.State.int random (Array.length floors)) in
  let sandworm = choose_far camel in
  let exit = choose_far ~excluded:[ sandworm ] camel in
  grid.(exit.row).(exit.col) <- Exit;
  (** [reachable_positions start] finds all non-wall cells reachable from
      [start]. *)
  let reachable_positions start =
    let visited = Array.make_matrix row_count col_count false in
    let rec visit positions = function
      | [] -> positions
      | position :: rest ->
          if
            position.row < 0
            || position.row >= row_count
            || position.col < 0
            || position.col >= col_count
            || visited.(position.row).(position.col)
            || grid.(position.row).(position.col) = Wall
          then visit positions rest
          else (
            visited.(position.row).(position.col) <- true;
            let neighbors =
              [
                { row = position.row - 1; col = position.col };
                { row = position.row; col = position.col + 1 };
                { row = position.row + 1; col = position.col };
                { row = position.row; col = position.col - 1 };
              ]
            in
            visit (position :: positions) (List.rev_append neighbors rest))
    in
    visit [] [ start ]
  in
  (** [occupied position] is [true] when [position] belongs to an actor or
      the exit. *)
  let occupied position =
    position = camel || position = sandworm || position = exit
  in
  let reachable_landing_spots =
    reachable_positions camel
    |> List.filter (fun position -> not (occupied position))
  in
  (** [choose_random positions] selects and removes one position from
      [positions]. *)
  let choose_random positions =
    let index = Random.State.int random (List.length positions) in
    let rec remove_at index = function
      | [] -> failwith "World.generate: invalid lambda position"
      | position :: rest ->
          if index = 0 then position, rest
          else
            let chosen, remaining = remove_at (index - 1) rest in
            chosen, position :: remaining
    in
    remove_at index positions
  in
  let first, remaining = choose_random reachable_landing_spots in
  let second, remaining = choose_random remaining in
  let optional_lambdas =
    List.filter (fun _ -> Random.State.int random 4 = 0) remaining
    |> List.map (fun position -> position, Copper)
  in
  let lambdas =
    (first, Gold) :: (second, Silver) :: optional_lambdas
  in
  from_setup { grid; camel; sandworm; exit; lambdas }
