# ocaml-webview

A cross-platform wrapper of [webview](https://github.com/zserge/webview) for OCaml.
Allows you to pop open a webview from OCaml code, then to programmatically close it
or cause it to execute JavaScript.

## Usage

```ocaml
(webview, thread) = Webview.run "https://github.com/zserge/webview"
```

Status: **pre-release**. Expect breaking changes, build failures and segfaults.
