// Snake em raylib - jogo simples feito para o trabalho de CSI412.
// Setas ou WASD movem a cobra; ENTER reinicia depois do game over.

#include "raylib.h"

#define CELL 30
#define GRID 20
#define STEP_TIME 0.1f

typedef struct { int x, y; } Cell;

// Posicoes da cobra; snake[0] e a cabeca
static Cell snake[GRID*GRID];
static int length;
// Direcao do ultimo passo executado
static Cell dir;
// Direcao pedida para o proximo passo
static Cell nextDir;
static Cell food;
static int score;
static bool gameOver;

// Sorteia uma celula livre para a comida; sem celula livre, o jogo termina
static void SpawnFood(void)
{
    int freeCells = GRID*GRID - length;
    if (freeCells <= 0)
    {
        gameOver = true;
        return;
    }

    // Escolhe a k-esima celula livre, contando a partir do canto superior esquerdo
    int k = GetRandomValue(0, freeCells - 1);
    for (int y = 0; y < GRID; y++)
    {
        for (int x = 0; x < GRID; x++)
        {
            bool occupied = false;
            for (int i = 0; i < length; i++)
            {
                if (snake[i].x == x && snake[i].y == y) occupied = true;
            }
            if (occupied) continue;

            if (k == 0)
            {
                food = (Cell){ x, y };
                return;
            }
            k--;
        }
    }
}

// Cobra de tamanho 3 no centro, indo para a direita
static void ResetGame(void)
{
    length = 3;
    for (int i = 0; i < length; i++) snake[i] = (Cell){ GRID/2 - i, GRID/2 };
    dir = (Cell){ 1, 0 };
    nextDir = dir;
    score = 0;
    gameOver = false;
    SpawnFood();
}

// Pede uma nova direcao; so vale se nao for a oposta e se nao houver outra curva pedida neste passo
static void TryTurn(int dx, int dy)
{
    bool turnPending = (nextDir.x != dir.x) || (nextDir.y != dir.y);
    bool isOpposite = (dx == -dir.x) && (dy == -dir.y);
    if (turnPending || isOpposite) return;

    nextDir = (Cell){ dx, dy };
}

static void HandleInput(void)
{
    if (gameOver)
    {
        if (IsKeyPressed(KEY_ENTER)) ResetGame();
        return;
    }

    if (IsKeyPressed(KEY_UP) || IsKeyPressed(KEY_W)) TryTurn(0, -1);
    else if (IsKeyPressed(KEY_DOWN) || IsKeyPressed(KEY_S)) TryTurn(0, 1);
    else if (IsKeyPressed(KEY_LEFT) || IsKeyPressed(KEY_A)) TryTurn(-1, 0);
    else if (IsKeyPressed(KEY_RIGHT) || IsKeyPressed(KEY_D)) TryTurn(1, 0);
}

// Avanca a cobra uma celula; trata parede, corpo e comida
static void StepGame(void)
{
    dir = nextDir;
    Cell head = { snake[0].x + dir.x, snake[0].y + dir.y };

    if (head.x < 0 || head.x >= GRID || head.y < 0 || head.y >= GRID)
    {
        gameOver = true;
        return;
    }

    // Se nao comer, a cauda sai do lugar neste passo e a cabeca pode ocupar a celula dela
    bool eats = (head.x == food.x) && (head.y == food.y);
    int bodyEnd = eats ? length : length - 1;
    for (int i = 0; i < bodyEnd; i++)
    {
        if (snake[i].x == head.x && snake[i].y == head.y)
        {
            gameOver = true;
            return;
        }
    }

    int newLength = eats ? length + 1 : length;
    for (int i = newLength - 1; i > 0; i--) snake[i] = snake[i - 1];
    snake[0] = head;
    length = newLength;

    if (eats)
    {
        score++;
        SpawnFood();
    }
}

static void DrawGame(void)
{
    ClearBackground(RAYWHITE);

    for (int i = 0; i <= GRID; i++)
    {
        DrawLine(i*CELL, 0, i*CELL, GRID*CELL, LIGHTGRAY);
        DrawLine(0, i*CELL, GRID*CELL, i*CELL, LIGHTGRAY);
    }

    DrawRectangle(food.x*CELL, food.y*CELL, CELL, CELL, RED);
    for (int i = 0; i < length; i++)
    {
        DrawRectangle(snake[i].x*CELL, snake[i].y*CELL, CELL, CELL, (i == 0)? DARKGREEN : GREEN);
    }

    DrawText(TextFormat("Pontos: %d", score), 10, 10, 20, DARKGRAY);

    if (gameOver)
    {
        const char *title = (length == GRID*GRID)? "Voce venceu!" : "Game over";
        const char *info = TextFormat("Pontos: %d - ENTER para reiniciar", score);
        DrawRectangle(0, GRID*CELL/2 - 50, GRID*CELL, 100, Fade(BLACK, 0.7f));
        DrawText(title, (GRID*CELL - MeasureText(title, 30))/2, GRID*CELL/2 - 35, 30, RAYWHITE);
        DrawText(info, (GRID*CELL - MeasureText(info, 20))/2, GRID*CELL/2 + 10, 20, RAYWHITE);
    }
}

int main(void)
{
    InitWindow(GRID*CELL, GRID*CELL, "Snake");
    SetTargetFPS(60);

    ResetGame();
    float timer = 0.0f;

    while (!WindowShouldClose())
    {
        HandleInput();

        // Acumula o tempo e avanca a cobra a cada STEP_TIME segundos
        if (!gameOver)
        {
            timer += GetFrameTime();
            while (timer >= STEP_TIME && !gameOver)
            {
                timer -= STEP_TIME;
                StepGame();
            }
        }

        BeginDrawing();
            DrawGame();
        EndDrawing();
    }

    CloseWindow();
    return 0;
}
