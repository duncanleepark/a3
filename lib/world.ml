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

let rows world =
  Array.length world.grid

let cols world =
  if rows world = 0 then 0 else Array.length world.grid.(0)

let in_bounds grid position =
  position.row >= 0
  && position.row < Array.length grid
  && position.col >= 0
  && position.col < Array.length grid.(position.row)

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

let terrain_at world position =
  world.grid.(position.row).(position.col).terrain

let lambda_at world position =
  world.grid.(position.row).(position.col).lambda

let collect_lambda world position =
  let cell = world.grid.(position.row).(position.col) in
  let collected = cell.lambda in
  cell.lambda <- None;
  collected

let camel_position world = world.camel
let sandworm_position world = world.sandworm
let exit_position world = world.exit

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

let generate seed =
  let random = Random.State.make [| seed |] in
  let row_count = 15 in
  let col_count = 45 in
  let grid = Array.make_matrix row_count col_count Wall in
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
  let floors = ref [] in
  Array.iteri
    (fun row cells ->
      Array.iteri
        (fun col terrain ->
          if terrain = Floor then floors := { row; col } :: !floors)
        cells)
    grid;
  let floors = Array.of_list !floors in
  let choose_far position =
    let candidates =
      Array.to_list floors
      |> List.filter (fun other ->
           abs (position.row - other.row) + abs (position.col - other.col) >= 6)
    in
    List.nth candidates (Random.State.int random (List.length candidates))
  in
  let camel = floors.(Random.State.int random (Array.length floors)) in
  let sandworm = choose_far camel in
  let exit = choose_far camel in
  grid.(exit.row).(exit.col) <- Exit;
  let occupied position =
    position = camel || position = sandworm || position = exit
  in
  let lambda_positions =
    Array.to_list floors
    |> List.filter (fun position -> not (occupied position))
    |> List.filter (fun _ -> Random.State.int random 4 = 0)
  in
  let lambdas =
    match lambda_positions with
    | first :: second :: rest ->
        (first, Gold) :: (second, Silver)
        :: List.map (fun position -> (position, Copper)) rest
    | first :: [] -> [ (first, Gold) ]
    | [] -> []
  in
  from_setup { grid; camel; sandworm; exit; lambdas }
