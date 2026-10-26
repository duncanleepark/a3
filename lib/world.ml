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