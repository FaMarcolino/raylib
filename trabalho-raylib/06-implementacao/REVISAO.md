# Revisão do Pull Request (feita pelo outro integrante)


- **Autor do PR:** conta GitHub `FaMarcolino`
- **Revisor(a):** conta GitHub `luanpais` (integrante diferente do autor)
- **Link do PR:** https://github.com/raysan5/raylib/pull/6400 (PR ao projeto original, **fechado pelo mantenedor em 10/11/2026 sem mesclar**; o código revisado continua na branch `feat/headless-tests`. PR interno de revisão no fork: https://github.com/FaMarcolino/raylib/pull/1)
- **Data da revisão:** testes e teste de mutação executados em 10/11/2026; parecer publicado em 13/11/2026 no PR #1 do fork (https://github.com/FaMarcolino/raylib/pull/1)

## Roteiro de revisão

### A. Ler e entender (sem executar)
- [x] O PR toca apenas `tests/` e `.github/workflows/run_tests.yml` (nenhum `src/`)? **Sim: 7 arquivos, nenhum em `src/`.**
- [x] Cada valor esperado em `test_hash.c` tem origem independente do raylib? **Sim: os valores vêm do .NET (`System.Security.Cryptography`). O revisor recalculou 1 valor (`'a'` × 56, linha 21) no PowerShell e bateu.** Os comprimentos testados são as fronteiras do padding de 512 bits, onde existia o bug do PR #6144.
- [x] `KNOWN_BUG` (se houver) cita issue/PR real? **O PR #6348 está Merged (commit `7e626d65`) e o teste das sequências truncadas em `test_utf8.c` (linha 41) hoje é `CHECK`, não `KNOWN_BUG`.**
- [x] O código dos testes segue `CONVENTIONS.md` (4 espaços, sem TAB, comentário antes da linha, `float x.xf`)? **Segue na maior parte.** Conferido com `grep`: não há TAB nem espaço no fim da linha nos `.c` e `.h` de `tests/`. Desvios pequenos:
  - comentários no fim da linha (`test_utf8.c` linhas 25 a 28 e `test_paths.c`);
  - comentários terminando com ponto (`test_utf8.c` linhas 33 e 34);
  - funções `static` de teste em `snake_case`, quando a convenção pede `TitleCase`.

### B. Executar
```bash
cd src && make PLATFORM=PLATFORM_DESKTOP
cd ../tests && make test
```
- [x] Saída final `ALL TEST FILES PASSED`. Contagens: `test_hash` 65 · `test_paths` 29 · `test_utf8` 26 (0 falhas, 0 XFAIL, 0 XPASS). Ambiente do revisor: Windows, MSYS2 UCRT64, gcc 16.2.0, GNU Make 4.4.1, em 10/11/2026.

### C. Conferir um valor por conta própria
PowerShell (SHA-256 de `'a'` × 56 deve ser `b35439a4…6738a`):
```powershell
$b=[byte[]]@(0x61)*56; ([BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($b))).Replace('-','').ToLower()
```
- [x] Bateu com o esperado em `test_hash.c` (linha 21).

### D. Teste de mutação (o teste realmente pega o bug?)
1. Crie uma **cópia** de `src/` (não altere o original).
2. Em `rcore.c`, na linha do `paddedSize` do `ComputeSHA256`, troque `sizeof(bitLen)` por `sizeof(dataSize)` (reintroduz o bug do padding; equivale a `dataSize + 4`).
3. Apague os objetos da cópia (`rm -f *.o libraylib.a`), recompile **gravando a biblioteca dentro da cópia** (`make PLATFORM=PLATFORM_DESKTOP RAYLIB_RELEASE_PATH=.`; sem isso o Makefile grava em `../src/` e sobrescreve a biblioteca **original**) e rode `test_hash` apontando `RAYLIB_SRC` para a cópia.
- [x] `test_hash` falhou nos comprimentos 56, 57, 59, 120 e 121 (`65 checks, 5 failed`; `make` terminou com `Error 1`); 0, 1, 3, 55, 60, 63, 64, 65 e 119 seguiram `ok`. Ao restaurar a biblioteca original, voltou a `ALL TEST FILES PASSED`.
  - **Nota honesta:** a 1ª tentativa foi **inválida** — o `make` gravou a biblioteca mutada em `../src/` e os testes linkaram com a cópia original, então passaram. O revisor percebeu, reconstruiu a biblioteca original e refez com `RAYLIB_RELEASE_PATH=.` (o roteiro acima já foi corrigido).

### E. Pontos de atenção que a revisão deve avaliar
- [x] Testes de caminho absoluto dependem de `#ifdef _WIN32` — ok para Linux/macOS? **Os casos de Windows do `test_paths.c` (dentro de `#if defined(_WIN32)`) só foram executados no computador do revisor; o CI roda apenas em Linux.**
- [x] Workflow de CI: **`Run headless tests` verde no fork (`FaMarcolino/raylib`, execução #6, PR #1).** (Histórico, com os hashes de antes do rebase de 10/11/2026: a 1ª execução, no commit `9657563`, falhou; a do commit `b83e2d3`, com `libglfw3-dev`, passou.) No PR #6400 original a aba *Checks* mostra 0 (PR fechado), então a evidência de CI vem do fork. O build do macOS (workflow separado) falhou uma vez (#3) e passou nas execuções seguintes (#4 na master e #5 na branch): parece intermitente e sem ligação com os testes novos, mas o log da #3 não foi aberto para confirmar a causa.
- [x] Algum teste "trava" o processo? **Nenhum trava, e `GetFileExtension(NULL)` não está na suíte.**

## Parecer

- **Resultado:** **aprovado com ressalvas**
- **Comentários principais:**
  - Só `tests/` e `run_tests.yml` mudaram; rodei a suíte no Windows (gcc 16.2.0) e passou; o teste de mutação falhou nos comprimentos 56, 57, 59, 120 e 121, como estava esperando.
  - Boa escolha o oráculo independente (.NET) e a cobertura das fronteiras do padding de 512 bits.
  - **Ressalvas:**
    1. Falta o comprimento 58, que também está na faixa do bug (módulo 64 entre 56 e 59).
    2. A verificação de UTF-8 truncado é fraca: `CHECK(size <= strlen(...))` só confere que o tamanho não passa do fim da string, enquanto os casos inválidos das linhas 25 a 28 conferem também o valor retornado (`'?'`). Faz sentido se o objetivo é só evitar leitura fora da string.
    3. Os testes de caminho específicos do Windows só rodam localmente (o CI é Linux).
    4. O workflow do macOS falhou uma vez (#3), de forma aparentemente intermitente.
    5. Estilo: comentários no fim da linha, comentários terminando com ponto e funções `static` em `snake_case`. São detalhes pequenos, que não pedem mudança para aprovar.
    6. O comentário `STATUS:` no `run_tests.yml` tende a ficar desatualizado, já que o histórico fica no Git.
    7. Algumas funções têm poucos casos: `GetFileNameWithoutExt` tem só 2 e `IsFileExtension` não testa `NULL`.
- **Mudanças feitas após a revisão (commits):** Nenhuma. As ressalvas não bloqueiam a aprovação e ficam registradas como melhorias futuras (comprimento 58, UTF-8 truncado, casos extras).
