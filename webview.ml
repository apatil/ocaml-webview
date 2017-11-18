open Thread

type t

external empty_wrap : unit -> t = "empty_wrap"
external webview_wrap : string -> string -> int -> int -> int -> int = "webview_wrap"
external init_wrap : string -> string -> int -> int -> int -> (t * int) = "init_wrap"
external loop_wrap : t -> int -> int = "loop_wrap"
external run_wrap  : t -> (string * string * int * int * int) -> int = "run_wrap"
external terminate_wrap : t -> unit = "terminate_background"
external exit_wrap : t -> unit = "exit_background"
external set_title_wrap : string -> t -> unit = "set_title_background"
external eval_wrap : string -> t -> int = "eval_background"

let init ?(title = "") ?(width = 800) ?(height = 600) ?(resizable = true) url =
  let (wv, code) = init_wrap title url width height (if resizable then 1 else 0) in
  match code with
  | 0 -> Ok wv
  | _ -> Error "Failed to init webview"

let loop ?(blocking=true) wv =
  loop_wrap wv (if blocking then 1 else 0)

let run ?(title = "") ?(width = 800) ?(height = 600) ?(resizable = true) url =
  let wv = empty_wrap () in
  let runner () =
    let code = try
        run_wrap wv (title, url, width, height, (if resizable then 1 else 0))
    with _ -> 1
    in
    ()
  in
  let thread = Thread.create runner () in
  (wv, thread)

let set_title ~title wv =
  set_title_wrap title wv

let eval ~js wv =
  match eval_wrap js wv with
  | 0 -> Ok ()
  | _ -> Error "Failed to eval JavaScript"

let terminate (wv, thread) =
  terminate_wrap wv;
  Thread.join thread

let exit (wv, thread) =
  exit_wrap wv;
  Thread.join thread
