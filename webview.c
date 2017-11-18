#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/threads.h>
#include <caml/signals.h>
#include "./webview.h"
#include <stdio.h>


CAMLprim value
webview_wrap( value title, value url, value width, value height, value resizable )
{
    char *t;
    char *u;
    t = String_val(title);
    u = String_val(url);
    caml_release_runtime_system();
    // printf("Creating C webview");
    webview(t, u, Int_val(width), Int_val(height), Int_val(resizable));
    // printf("C webview exited");
    caml_acquire_runtime_system();
    return Val_unit;
}

struct webview
*webview_new(value title, value url, value width, value height, value resizable )
{
  struct webview *wv = malloc (sizeof (*wv));
  wv->title = String_val(title);
  wv->url = String_val(url);
  wv->width = Int_val(width);
  wv->height = Int_val(height);
  wv->resizable = Int_val(resizable);

  // printf("Webview_new got title %s\n url %s\n width %d\n height %d\n resizeable %d\n", wv->title, wv->url, wv->width, wv->height, wv->resizable);
  return wv;
}
CAMLprim value
init_wrap(value title, value url, value width, value height, value resizable)
{
  CAMLparam5(title, url, width, height, resizable);
  CAMLlocal1( out );

  struct webview *wv = webview_new(title, url, width, height, resizable);
  // printf("Webview_new returned %p\n", wv);
  int code = webview_init(wv);
  // printf("Webview_init code %d\n", code);

  out = caml_alloc(2, 0);
  Store_field( out, 1, Int_val(code) );

  if (code == 0) {
    Store_field( out, 1, Int_val(code) );
    Store_field( out, 0, (value) wv );
  }

  CAMLreturn( out );

}

CAMLprim value
loop_wrap(value ocaml_wv, value blocking)
{
  struct webview* wv;
  wv = (struct webview *)ocaml_wv;
  // printf("Loop got %p\n blocking %d\n", wv, Int_val(blocking));
  int block = Int_val(blocking);
  int code = webview_loop(wv, block);
  // printf("Loop code %d\n", code);
  return Val_int(code);
}

CAMLprim value
empty_wrap(value ocaml_wv)
{
  struct webview* wv  = malloc (sizeof (*wv));
  return (value) wv;
}

CAMLprim value
run_wrap(value ocaml_wv, value params)
{
  CAMLparam2(ocaml_wv, params);

  struct webview* wv;
  wv = (struct webview *)ocaml_wv;
  const char* title = String_val(Field(params, 0));
  const char* url = String_val(Field(params, 1));
  int width = Int_val(Field(params, 2));
  int height = Int_val(Field(params, 3));
  int resizable = Int_val(Field(params, 4));

  wv->title = title;
  wv->url = url;
  wv->width = width;
  wv->height = height;
  wv->resizable = resizable;

  // printf("Webview_new returned %p\n", wv);
  int code = webview_init(wv);
  // printf("Webview_init code %d\n", code);

  // int code = 0;
  if (code == 0) {
    // printf("   Run_wrap starting\n");
    caml_release_runtime_system();
    int still_ok = true;
    while(still_ok) {
      int res = webview_loop(wv, 0);
      // printf("   Loop returned %d", res);
      still_ok = res == 0;
    }
    webview_exit(wv);
    caml_acquire_runtime_system();
    // printf("   Run_wrap returning\n");
  }

  CAMLreturn(Val_int(code));
}


// Operations on a webview in a background thread
void terminate_dispatch(struct webview *wv, void *arg) {
  webview_terminate(wv);
}
CAMLprim value
terminate_background(value ocaml_wv)
{
  struct webview* wv;
  wv = (struct webview *)ocaml_wv;
  void *arg;
  webview_dispatch(terminate_dispatch, wv, arg);
  return Val_unit;
}


void exit_dispatch(struct webview *wv, void *arg) {
  webview_exit(wv);
}
CAMLprim value
exit_background(value ocaml_wv)
{
  // printf("Exit background called\n");
  struct webview* wv;
  wv = (struct webview *)ocaml_wv;
  void *arg;
  // printf("Calling dispatch\n");
  webview_dispatch(exit_dispatch, wv, arg);
  // printf("Dispatch finished\n");
  return Val_unit;
}

void set_title_dispatch(struct webview *wv, void *arg) {
  const char *title;
  title = (const char *) arg;
  webview_set_title(wv, &title);
}
CAMLprim value
set_title_background(value title, value ocaml_wv)
{
  struct webview* wv;
  wv = (struct webview *)ocaml_wv;
  void *arg;
  arg = (void *) String_val(title);
  webview_dispatch(set_title_dispatch, wv, arg);
  return Val_unit;
}


void eval_dispatch(struct webview *wv, void *arg) {
  const char *js;
  js = (const char *) arg;
  webview_eval(wv, &js);
}
CAMLprim value
eval_background(value js, value ocaml_wv)
{
  struct webview* wv;
  wv = (struct webview *)ocaml_wv;
  void *arg;
  arg = (void *) String_val(js);
  webview_dispatch(eval_dispatch, wv, arg);
  return Val_unit;
}
