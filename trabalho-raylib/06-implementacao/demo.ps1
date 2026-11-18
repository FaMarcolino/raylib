# demo.ps1 - mostra na pratica a proposta: testes headless que pegam bugs de verdade.
#
# O que faz (leva ~15 segundos com a biblioteca ja compilada):
#   1) roda os 3 arquivos de teste (120 verificacoes) contra o raylib original;
#   2) reintroduz o bug do padding do ComputeSHA256 numa COPIA de src/ (o original nao e alterado)
#      e roda test_hash: os testes devem FALHAR nos comprimentos 56, 57, 59, 120 e 121;
#   3) roda test_hash de novo no raylib original: volta a passar.
# A saida tambem e gravada em demo-saida.txt (por padrao, ao lado deste script).
#
# PRE-REQUISITOS: gcc e mingw32-make no PATH (MSYS2 UCRT64) e uma copia da branch feat/headless-tests
# do fork com a biblioteca compilada:
#     git worktree add ../raylib-demo feat/headless-tests
#     cd ../raylib-demo/src ; mingw32-make PLATFORM=PLATFORM_DESKTOP
#
# USO:
#     powershell -ExecutionPolicy Bypass -File demo.ps1 -Raiz ..\..\..\raylib-demo

param(
    [string]$Raiz = (Get-Location).Path,
    [string]$Saida = (Join-Path $PSScriptRoot 'demo-saida.txt')
)

$ErrorActionPreference = 'Stop'
$src = Join-Path $Raiz 'src'
$tests = Join-Path $Raiz 'tests'

if (-not (Test-Path (Join-Path $src 'libraylib.a')) -or -not (Test-Path (Join-Path $tests 'test_hash.c'))) {
    Write-Host "Nao encontrei src\libraylib.a e tests\test_hash.c em '$Raiz'." -ForegroundColor Red
    Write-Host "Use -Raiz com uma copia da branch feat/headless-tests com a biblioteca compilada (veja o topo deste arquivo)." -ForegroundColor Red
    exit 2
}

$make = if (Get-Command mingw32-make -ErrorAction SilentlyContinue) { 'mingw32-make' } else { 'make' }
$tmp = Join-Path ([IO.Path]::GetTempPath()) ('raylib-demo-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $tmp | Out-Null
$log = New-Object System.Collections.Generic.List[string]

function Say([string]$texto, [string]$cor = 'Gray') {
    Write-Host $texto -ForegroundColor $cor
    $log.Add($texto)
}

# Compila um arquivo de teste contra a biblioteca da pasta $srcDir e devolve o caminho do .exe
function Compilar([string]$nome, [string]$srcDir) {
    $exe = Join-Path $tmp ($nome + '-' + [guid]::NewGuid().ToString('N').Substring(0, 6) + '.exe')
    & gcc -std=c99 -Wall -Wextra -Wno-unused-function "-I$srcDir" -o $exe (Join-Path $tests "$nome.c") "-L$srcDir" -lraylib -lopengl32 -lgdi32 -lwinmm
    if ($LASTEXITCODE -ne 0) { throw "falha ao compilar $nome" }
    return $exe
}

# Roda um teste e mostra so as linhas que interessam; devolve o codigo de saida
function Rodar([string]$nome, [string]$srcDir, [bool]$detalhe) {
    $exe = Compilar $nome $srcDir
    $saida = & $exe
    $codigo = $LASTEXITCODE
    foreach ($linha in $saida) {
        if ($detalhe -and $linha -match '^\s+sha256 len=') {
            $cor = if ($linha -match 'MISMATCH') { 'Red' } else { 'Green' }
            Say "    $($linha.Trim())" $cor
        }
        elseif ($linha -match '\bchecks,') {
            $cor = if ($codigo -eq 0) { 'Green' } else { 'Red' }
            Say "    $($linha.Trim())" $cor
        }
    }
    return $codigo
}

try {
    Say '=== Demo: testes headless do raylib ===' 'Cyan'
    Say ("Data: " + (Get-Date -Format 'dd/MM/yyyy HH:mm') + " | " + ((& gcc --version)[0]))
    Say ''

    # ---------- 1) suite completa no raylib original ----------
    Say '1) Suite completa no raylib ORIGINAL (sem janela, sem GPU)' 'Cyan'
    $todosPassaram = $true
    foreach ($nome in 'test_hash', 'test_paths', 'test_utf8') {
        Say "  $nome"
        $codigo = Rodar $nome $src $false
        if ($codigo -ne 0) { $todosPassaram = $false }
    }
    if (-not $todosPassaram) { Say '  Algum teste falhou no raylib original - pare e investigue antes da demo.' 'Red'; throw 'suite original falhou' }
    Say '  => ALL TEST FILES PASSED' 'Green'
    Say ''

    # ---------- 2) mutacao: reintroduz o bug numa copia ----------
    Say '2) Quebramos o ComputeSHA256 de proposito (so numa COPIA de src/)' 'Cyan'
    $srcMut = Join-Path $tmp 'src_mut'
    Copy-Item -Recurse -Path $src -Destination $srcMut
    $rcore = Join-Path $srcMut 'rcore.c'
    $texto = [IO.File]::ReadAllText($rcore)
    $novo = $texto.Replace('paddedSize = dataSize + sizeof(bitLen)', 'paddedSize = dataSize + sizeof(dataSize)')
    if ($novo -eq $texto) { throw 'nao achei a linha do paddedSize em rcore.c (o codigo mudou?)' }
    [IO.File]::WriteAllText($rcore, $novo, (New-Object System.Text.UTF8Encoding($false)))
    Say '  Mutacao: sizeof(bitLen) -> sizeof(dataSize) na linha do paddedSize (reserva so 4 bytes para o tamanho da mensagem)'
    Remove-Item (Join-Path $srcMut 'rcore.o'), (Join-Path $srcMut 'libraylib.a') -ErrorAction SilentlyContinue
    # A saida do make (com avisos do gcc) vai para arquivos temporarios, para nao poluir a demo
    $proc = Start-Process -FilePath $make -ArgumentList @('-C', "`"$srcMut`"", 'PLATFORM=PLATFORM_DESKTOP', 'RAYLIB_RELEASE_PATH=.') `
        -NoNewWindow -Wait -PassThru -RedirectStandardOutput (Join-Path $tmp 'make.out') -RedirectStandardError (Join-Path $tmp 'make.err')
    if ($proc.ExitCode -ne 0) { throw 'falha ao recompilar a copia mutada' }
    Say '  test_hash contra a biblioteca QUEBRADA:'
    $codigoMut = Rodar 'test_hash' $srcMut $true
    if ($codigoMut -eq 0) { Say '  ATENCAO: a mutacao NAO foi detectada.' 'Red'; throw 'mutacao nao detectada' }
    Say '  => o teste DETECTOU o bug (codigo de saida diferente de 0)' 'Green'
    Say ''

    # ---------- 3) original de novo ----------
    Say '3) Raylib ORIGINAL de novo (a copia quebrada foi descartada)' 'Cyan'
    $codigoFinal = Rodar 'test_hash' $src $false
    if ($codigoFinal -ne 0) { throw 'test_hash falhou no original' }
    Say '  => voltou a passar' 'Green'
}
finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
    $log | Out-File -FilePath $Saida -Encoding utf8
    Write-Host ''
    Write-Host "Saida gravada em: $(Split-Path $Saida -Leaf)" -ForegroundColor DarkGray
}
