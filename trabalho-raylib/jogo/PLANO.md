# Jogo Snake em raylib — Plano de implementação

> **Para quem executa:** use superpowers:subagent-driven-development (recomendado) ou superpowers:executing-plans. Os passos usam caixas `- [ ]`.

**Objetivo:** entregar um Snake jogável em um único arquivo C, compilado contra o `libraylib.a` do fork.

**Arquitetura:** um `snake.c` com estado global pequeno e funções separadas para reiniciar, ler entrada, avançar um passo e desenhar. O laço principal chama essas funções a cada quadro, e o passo da cobra roda em um temporizador.

**Tecnologias:** C99, raylib (snapshot do fork), gcc 14.2 e `mingw32-make` (MSYS2, Windows).

**Spec:** [DESIGN.md](DESIGN.md)

## Restrições globais

- Um único arquivo de código: `jogo/snake.c`, uns 150 a 200 linhas, C, sem imagens nem sons.
- Janela 600x600; grade 20x20 com células de 30 px; 10 passos por segundo.
- Controles: setas ou WASD; `ENTER` reinicia depois do game over.
- A cobra é um array fixo de 400 posições (grade inteira).
- Compilar com `-std=c99 -Wall -Wextra` sem nenhum aviso.
- Não alterar `src/`, `tests/` nem o CI. Tudo fica em `trabalho-raylib/jogo/`.
- Os `git commit` são feitos pela dupla; o plano só indica os arquivos de cada commit.

## Foco da revisão

Situações que o design implica, mas que os passos não verificam sozinhos. Cada uma tem uma verificação manual na tarefa 2 ou 3.

1. Apertar a direção oposta (cobra indo à direita e o jogador aperta esquerda): a cobra **não** pode se virar sobre si mesma.
2. Dois toques de direção no mesmo passo (cima e depois esquerda, rápido): só a primeira direção válida vale, e a cobra não morre por isso.
3. A comida **nunca** nasce em cima da cobra.
4. A cobra ocupando toda a grade (400 células): o jogo não pode travar procurando lugar para a comida; deve terminar.
5. `ENTER` fora do game over não faz nada, e depois de reiniciar a pontuação e o tamanho voltam ao valor inicial.

---

### Tarefa 1: Esqueleto — Makefile e janela

**Arquivos:**
- Criar: `trabalho-raylib/jogo/Makefile`
- Criar: `trabalho-raylib/jogo/snake.c`

**Interfaces:**
- Produz: constantes `CELL` (30), `GRID` (20), `STEP_TIME` (0.1f); `int main(void)` que abre a janela 600x600 e desenha a grade até `ESC`.

- [ ] **Passo 1: Escrever o `Makefile`.** Variável `RAYLIB_SRC ?= ../../src`. No Windows, `LIBS = -L$(RAYLIB_SRC) -lraylib -lopengl32 -lgdi32 -lwinmm`, como em `tests/Makefile` da branch `feat/headless-tests`. `CFLAGS = -std=c99 -Wall -Wextra -I$(RAYLIB_SRC)`. Alvos `snake.exe` (padrão) e `clean`.
- [ ] **Passo 2: Escrever `snake.c` com as constantes e `main`.** `InitWindow(GRID*CELL, GRID*CELL, "Snake")`, `SetTargetFPS(60)`, laço até `WindowShouldClose()`, e no desenho `ClearBackground` mais uma linha de grade por célula.
- [ ] **Passo 3: Compilar.** Rodar `mingw32-make` em `trabalho-raylib/jogo`. Esperado: gera `snake.exe`, **sem avisos**.
- [ ] **Passo 4: Executar** `./snake.exe`. Esperado: janela 600x600 com a grade; `ESC` fecha sem travar.
- [ ] **Passo 5: Commit** de `Makefile` e `snake.c` (mensagem sugerida: `jogo: esqueleto com janela e grade`).

---

### Tarefa 2: Lógica do jogo

**Arquivos:**
- Modificar: `trabalho-raylib/jogo/snake.c`

**Interfaces:**
- Consome: constantes da tarefa 1.
- Produz (todas `static`, em `snake.c`):
  - `typedef struct { int x, y; } Cell;`
  - estado global: `Cell snake[GRID*GRID]; int length; Cell dir; Cell food; int score; bool gameOver;`
  - `void ResetGame(void)` — cobra de tamanho 3 no centro indo para a direita, `score = 0`, `gameOver = false`, chama `SpawnFood()`.
  - `void SpawnFood(void)` — sorteia uma célula livre com `GetRandomValue`; se não houver célula livre, define `gameOver = true`.
  - `void HandleInput(void)` — lê setas/WASD e grava a direção **pedida**, ignorando a oposta à direção do último passo executado.
  - `void StepGame(void)` — move a cabeça; se bater na parede ou em si, `gameOver = true`; se pegar a comida, `length++`, `score++`, `SpawnFood()`.
  - `void DrawGame(void)` — grade, cobra, comida e `score` no canto.

- [ ] **Passo 1: Implementar `ResetGame`, `SpawnFood` e `StepGame`.** `StepGame` usa a direção travada no passo anterior para decidir se uma direção é oposta (resolve o foco 2). `SpawnFood` testa se a célula sorteada está na cobra e sorteia de novo; para o foco 4, conta as células livres antes de sortear.
- [ ] **Passo 2: Implementar `HandleInput` e `DrawGame`.** Cobra em verde, comida em vermelho, texto da pontuação com `DrawText`.
- [ ] **Passo 3: Ligar no `main`.** `ResetGame()` antes do laço; a cada quadro, `HandleInput()`; um acumulador de tempo com `GetFrameTime()` chama `StepGame()` a cada `STEP_TIME`, só se `!gameOver`; depois `DrawGame()`.
- [ ] **Passo 4: Compilar.** `mingw32-make`. Esperado: sem avisos.
- [ ] **Passo 5: Jogar e conferir à mão.**
  - Comer aumenta o tamanho e a pontuação em 1.
  - Bater na parede ou em si mesma congela o jogo.
  - Foco 1: pressionar a direção oposta não vira a cobra.
  - Foco 2: dois toques rápidos de direção não matam a cobra.
  - Foco 3: jogar até a cobra ficar grande e ver que a comida nunca aparece sobre ela.
- [ ] **Passo 6: Commit** de `snake.c` (`jogo: lógica de movimento, comida e colisão`).

---

### Tarefa 3: Game over, reinício, README e registro de IA

**Arquivos:**
- Modificar: `trabalho-raylib/jogo/snake.c`
- Criar: `trabalho-raylib/jogo/README.md`
- Modificar: `trabalho-raylib/08-ia/ia.md`

**Interfaces:**
- Consome: `gameOver`, `score`, `ResetGame()` da tarefa 2.
- Produz: tela de game over e reinício por `ENTER`.

- [ ] **Passo 1: Desenhar a mensagem de game over** em `DrawGame()` quando `gameOver`: texto "Game over — pontos: N" e "ENTER para reiniciar", centralizados.
- [ ] **Passo 2: Reiniciar com `ENTER`.** Em `HandleInput()`, só quando `gameOver` for verdadeiro, `IsKeyPressed(KEY_ENTER)` chama `ResetGame()`.
- [ ] **Passo 3: Compilar e jogar.** Esperado: sem avisos. Foco 5: `ENTER` durante o jogo não faz nada; após o game over e `ENTER`, tamanho volta a 3 e pontuação a 0.
- [ ] **Passo 4: Escrever o `README.md` do jogo.** Contém: o que é, como compilar (`cd trabalho-raylib/jogo && mingw32-make`, exigindo `src/libraylib.a` já compilado), controles e quais funções do raylib ele usa (para a dupla poder explicar).
- [ ] **Passo 5: Registrar no `ia.md`.** Incluir o prompt do professor/dupla ("criar um jogo fácil"), que a IA escreveu e testou o código, e que a dupla deve conseguir explicar cada função. Ajustar também a tabela de estrutura do `README.md` raiz se vocês quiserem citar a pasta `jogo/`.
- [ ] **Passo 6: Commit** de `snake.c`, `README.md` e `ia.md` (`jogo: game over, reinício e documentação`).

---

## Autoverificação

- **Cobertura do design:** janela, grade, controles, pontuação, game over, reinício, Makefile, README e registro de IA estão nas tarefas 1 a 3. O vetor fixo de 400 posições está nas restrições.
- **Consistência de nomes:** `Cell`, `snake`, `length`, `dir`, `food`, `score`, `gameOver`, `ResetGame`, `SpawnFood`, `HandleInput`, `StepGame` e `DrawGame` aparecem iguais nas tarefas 2 e 3.
- **Limite honesto:** o jogo não tem testes automatizados. A verificação é compilar sem avisos e jogar conferindo à mão cada item do Foco da revisão.
