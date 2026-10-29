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

type t

(** [create ~seed] creates a game using a procedurally generated world. *)
val create : seed:int -> t
(** [of_world world] creates a game from an explicitly constructed [world]. *)
val of_world : World.world -> t

(** [world game] is the world used by [game]. *)
val world : t -> World.world
(** [camel_position game] is the camel's current position. *)
val camel_position : t -> World.position
(** [sandworm_position game] is the sandworm's current position. *)
val sandworm_position : t -> World.position
(** [score game] is the current score. *)
val score : t -> int
(** [turns game] is the number of completed turns. *)
val turns : t -> int
(** [outcome game] is the current outcome. *)
val outcome : t -> outcome

(** [is_revealed game position] is [true] if the camel has revealed [position]. *)
val is_revealed : t -> World.position -> bool
(** [reveal game position] marks an in-bounds [position] as revealed. *)
val reveal : t -> World.position -> unit
(** [act game action] applies [action] and updates the mutable game state. *)
val act : t -> action -> unit