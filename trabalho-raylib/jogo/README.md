# Snake em raylib

Jogo simples, em um único arquivo C ([`snake.c`](snake.c)), feito com o raylib a pedido do professor.
Design em [`DESIGN.md`](DESIGN.md) e plano em [`PLANO.md`](PLANO.md).

## Como compilar e jogar (Windows / MSYS2)

Pré-requisitos: `gcc` e `mingw32-make` (MSYS2) e a biblioteca já compilada do fork (`src/libraylib.a`).

```bash
# 1) Na raiz do fork, compile a biblioteca (uma vez)
cd src
mingw32-make PLATFORM=PLATFORM_DESKTOP

# 2) Compile e rode o jogo
cd ../trabalho-raylib/jogo
mingw32-make
./snake.exe
```

O `Makefile` usa `RAYLIB_SRC` (padrão `../../src`) para achar `raylib.h` e `libraylib.a`.

## Controles

| Tecla | Ação |
|---|---|
| Setas ou W A S D | mover a cobra |
| ENTER | reiniciar (só depois do game over) |
| ESC | sair |

Comer o quadrado vermelho dá 1 ponto e aumenta a cobra. Bater na parede ou no próprio corpo termina o jogo.
Se a cobra ocupar a grade inteira, aparece "Voce venceu!".

## Regras e detalhes do código

- Grade 20x20, células de 30 px, janela 600x600, 10 passos por segundo (`STEP_TIME`).
- A cobra é um vetor de posições (`snake[]`, 400 elementos); `snake[0]` é a cabeça.
- `TryTurn()` ignora a direção oposta e só aceita uma curva por passo, para a cobra não se virar sobre si mesma.
- A comida nasce sempre numa célula livre (`SpawnFood()`).
- Seguir a própria cauda não mata: a cauda sai do lugar no mesmo passo em que a cabeça entra.

## Funções do raylib usadas

`InitWindow`, `SetTargetFPS`, `WindowShouldClose`, `GetFrameTime`, `IsKeyPressed`, `GetRandomValue`,
`BeginDrawing`/`EndDrawing`, `ClearBackground`, `DrawLine`, `DrawRectangle`, `DrawText`, `MeasureText`,
`TextFormat`, `Fade`, `CloseWindow`.

## Como foi verificado

- Compila com `-std=c99 -Wall -Wextra` sem avisos.
- A lógica (reinício, movimento, parede, corpo, cauda, comida, direção oposta, duas curvas no mesmo passo,
  comida fora da cobra e grade cheia) foi conferida por um teste descartável sem janela; quebrar de propósito
  a regra da direção oposta fez o teste falhar. Esse teste **não** está no repositório.
- O jogo foi aberto e ficou rodando; a jogabilidade completa (teclado e tela) deve ser conferida jogando.
