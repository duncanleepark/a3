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
  if rows world = 0 then 0
  else Array.length world.grid.(0)

let terrain_at world position =
  world.grid.(position.row).(position.col).terrain

let lambda_at world position =
  world.grid.(position.row).(position.col).lambda

let camel_position world = world.camel
let sandworm_position world = world.sandworm
let exit_position world = world.exit
