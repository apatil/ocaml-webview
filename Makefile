.PHONY: install clean all

default: all

CFLAGS ?= -std=c99 -Wall -Wextra -pedantic -fPIC

TARGET_OS ?= $(OS)
ifeq ($(TARGET_OS),Windows_NT)
	TARGET=minimal.exe
	WEBVIEW_CFLAGS := -DWEBVIEW_WINAPI=1
	WEBVIEW_LDFLAGS := -lole32 -lcomctl32 -loleaut32 -luuid -mwindows
else ifeq ($(shell uname -s),Linux)
	WEBVIEW_CFLAGS := -DWEBVIEW_GTK=1 $(shell pkg-config --cflags gtk+-3.0 webkitgtk-3.0)
	WEBVIEW_LDFLAGS := $(shell pkg-config --libs gtk+-3.0 webkitgtk-3.0)
else ifeq ($(shell uname -s),Darwin)
	WEBVIEW_CFLAGS := -DWEBVIEW_COCOA=1 -x objective-c
	WEBVIEW_LDFLAGS := -framework Cocoa -framework WebKit
endif

_build/webview.o:
	mkdir -p _build
	cp webview.c _build
	cp c-webview/webview.h _build
	cd _build && \
	  $(CC) $(CFLAGS) $(WEBVIEW_CFLAGS) webview.c $(LDFLAGS) $(WEBVIEW_LDFLAGS) -c -o webview.o && \
		ocamlmklib -g $(LDFLAGS) $(WEBVIEW_LDFLAGS) webview.o -o webview

all: _build/webview.o
	cp webview.ml _build
	cp webview.mli _build
	# ocamlfind ocamlmklib -verbose $(LDFLAGS) $(WEBVIEW_LDFLAGS) webview.o webview.mli webview.ml -o webview
	cd _build && \
		ocamlfind ocamlc -g -thread -package threads -a -o webview.cma  webview.mli webview.ml -dllib -lwebview -cclib -lwebview -cclib "$(WEBVIEW_LDFLAGS)" && \
		ocamlfind ocamlopt -g -thread -package threads -a -o webview.cmxa  webview.mli webview.ml -cclib -lwebview -cclib "$(WEBVIEW_LDFLAGS)"
		# ocamlfind ocamlopt -package thread -a   -o webview.cmxa  webview.mli webview.ml -cclib -lwebview
		# ocamlfind ocamlc -thread -package unix,threads -cclib -ldllwebview webview.mli webview.ml -a -o webview.cma && \
		# ocamlfind ocamlopt -thread -package unix,threads -cclib -ldllwebview webview.mli webview.ml -a -o webview.cmxa

	# - rm webview.ml*
	# - rm webview.c

install:
	ocamlfind install webview META _build/webview.cm* _build/dllwebview.so -dll _build/dllwebview.so

clean:
	- rm -rf _build/*

.PHONY: clean
