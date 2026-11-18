# Design: jogo Snake em raylib (versão curta)

Data: 2026-11-18

## Intenção
O professor sugeriu que a dupla criasse "um jogo fácil" com o repositório do raylib. Não deu mais detalhes.
O jogo mostra que a dupla sabe usar a API do software que analisou.
Tem de ser pequeno o bastante para a dupla explicar cada linha na apresentação.

## Objetivos
- Snake jogável do início ao fim: mover, comer, crescer, perder, reiniciar.
- Um único arquivo `jogo/snake.c`, de uns 150 a 200 linhas, em C, sem imagens nem sons.
- Compilar com `mingw32-make` e linkar com o `libraylib.a` do fork.
- README curto com instruções para compilar e jogar.

## Não objetivos
- Sem menu, sem som, sem arquivos de recursos, sem salvar recorde.
- Sem alterar `src/`, `tests/` nem o CI do fork.
- Sem suporte a outras plataformas além de Windows/MSYS2 nesta versão.

## Anti-objetivos
- Código que a dupla não consiga explicar. Se uma parte for difícil, simplifica-se.
- Misturar o jogo com a intervenção de testes e confundir o que é evidência do trabalho.

## Restrições
- Linguagem C, API do raylib do snapshot do fork.
- Ambiente: Windows, gcc 14.2 e `mingw32-make` (MSYS2); `src/libraylib.a` já compilado.

## Abordagens consideradas
- **Pong:** mais simples, mas usa menos da API e tem menos estados de jogo.
- **Desvie dos blocos:** parecido com o Snake em esforço, mas menos reconhecível.
- **Snake (escolhida):** fácil de explicar, usa grade, temporizador, entrada e colisão, e tem estados (jogando, game over).

## Decisões
- **Do usuário:** o jogo é o Snake, que foi aceito como a recomendação.
- **Minhas escolhas (para conferir):**
  - A pasta é `trabalho-raylib/jogo/`.
  - Grade de 20x20 células de 30 px, janela de 600x600, 10 passos por segundo.
  - Controles: setas ou WASD; `ENTER` reinicia depois do game over.
  - Pontuação mostrada no canto da tela.
  - Compilação por `Makefile` na própria pasta, usando `RAYLIB_SRC` como nos testes.
  - A cobra é um vetor de posições (array fixo de 400 elementos, que cobre a grade inteira).

## Deixado para quem implementa
- Nomes de funções e variáveis.
- Cores exatas.
- Pequenos detalhes de colisão, como impedir inversão de 180 graus.

## Verificação
- Compilar sem avisos com `-Wall`.
- Rodar e jogar: comer aumenta a pontuação e o tamanho; bater na parede ou em si mesma encerra; `ENTER` reinicia.
- Registrar o uso de IA no `08-ia/ia.md`.
