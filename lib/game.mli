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

val create : seed:int -> t
val of_world : World.world -> t

val world : t -> World.world
val camel_position : t -> World.position
val sandworm_position : t -> World.position
val score : t -> int
val turns : t -> int
val outcome : t -> outcome

val is_revealed : t -> World.position -> bool
val reveal : t -> World.position -> unit
val act : t -> action -> unit