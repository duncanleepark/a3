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

type world

val rows : world -> int
val cols : world -> int

val generate : int -> world
val from_grid : terrain array array -> world

val terrain_at : world -> position -> terrain
val lambda_at : world -> position -> lambda option
val collect_lambda : world -> position -> lambda option

val camel_position : world -> position
val sandworm_position : world -> position
val exit_position : world -> position

val lambdas : world -> (position * lambda) list

type setup = {
  grid : terrain array array;
  camel : position;
  sandworm : position;
  exit : position;
  lambdas : (position * lambda) list;
}

val from_setup : setup -> world