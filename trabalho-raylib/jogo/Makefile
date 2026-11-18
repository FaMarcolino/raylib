# Snake em raylib (Windows/MSYS2)
#
# USO (depois de compilar src/libraylib.a no fork):
#     cd trabalho-raylib/jogo
#     mingw32-make
#     ./snake.exe
#
# VARIAVEL:
#     RAYLIB_SRC   pasta com raylib.h e libraylib.a   (padrao: ../../src)

RAYLIB_SRC ?= ../../src
CC         ?= gcc
CFLAGS     ?= -std=c99 -Wall -Wextra -I$(RAYLIB_SRC)
LIBS        = -L$(RAYLIB_SRC) -lraylib -lopengl32 -lgdi32 -lwinmm

snake.exe: snake.c
	$(CC) $(CFLAGS) -o $@ $< $(LIBS)

clean:
	rm -f snake.exe
