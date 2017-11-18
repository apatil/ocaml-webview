type t

val run : ?title:string -> ?width:int -> ?height:int -> ?resizable:bool -> string -> (t * Thread.t)
(** Opens a webview in a background thread. Returns a handle to the webview and to the thread. *)

val init : ?title:string -> ?width:int -> ?height:int -> ?resizable:bool -> string -> (t, string) result
(** Opens a webview in the foreground, does not start its application loop. *)

val loop : ?blocking:bool -> t -> int
(** Iterates a foreground webview's application loop.  *)

val terminate : (t * Thread.t) -> unit
(** Terminates a webview. *)

val exit : (t * Thread.t) -> unit
(** Exits a webview. *)

val set_title : title:string -> t -> unit
(** Changes the title of a webview. *)

val eval : js:string -> t -> (unit, string) result
(** Evaluates JavaScript in the context of a webview. *)
