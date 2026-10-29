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

(** [rows world] is the number of rows in [world]. *)
val rows : world -> int
(** [cols world] is the number of columns in [world]. *)
val cols : world -> int

(** [generate seed] creates a reproducible labyrinth from nonnegative [seed]. *)
val generate : int -> world
(** [from_grid grid] builds a world from [grid] using default actor positions. *)
val from_grid : terrain array array -> world

(** [terrain_at world position] is the terrain at [position]. *)
val terrain_at : world -> position -> terrain
(** [lambda_at world position] is the lambda at [position], if one remains. *)
val lambda_at : world -> position -> lambda option
(** [collect_lambda world position] removes and returns the lambda at [position],
    if present. *)
val collect_lambda : world -> position -> lambda option

(** [camel_position world] is the initial camel position. *)
val camel_position : world -> position
(** [sandworm_position world] is the initial sandworm position. *)
val sandworm_position : world -> position
(** [exit_position world] is the exit position. *)
val exit_position : world -> position

(** [lambdas world] is the list of lambdas not yet collected from [world]. *)
val lambdas : world -> (position * lambda) list

type setup = {
  grid : terrain array array;
  camel : position;
  sandworm : position;
  exit : position;
  lambdas : (position * lambda) list;
}

(** [from_setup setup] constructs a world from explicit terrain, actor, exit,
    and lambda data in [setup]. *)
val from_setup : setup -> world