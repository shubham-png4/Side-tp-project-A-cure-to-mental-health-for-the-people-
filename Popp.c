#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#define EMPTY 0
#define W_PAWN 1
#define W_KNIGHT 2
#define W_BISHOP 3
#define W_ROOK 4
#define W_QUEEN 5
#define W_KING 6

#define B_PAWN 7
#define B_KNIGHT 8
#define B_BISHOP 9
#define B_ROOK 10
#define B_QUEEN 11
#define B_KING 12

const int PIECE_VALUES[] = {0, 100, 320, 330, 500, 900, 20000, 100, 320, 330, 500, 900, 20000};

const int pawn_table[64] = {
     0,  0,  0,  0,  0,  0,  0,  0,
    50, 50, 50, 50, 50, 50, 50, 50,
    10, 10, 20, 30, 30, 20, 10, 10,
     5,  5, 10, 25, 25, 10,  5,  5,
     0,  0,  0, 20, 20,  0,  0,  0,
     5, -5,-10,  0,  0,-10, -5,  5,
     5, 10, 10,-20,-20, 10, 10,  5,
     0,  0,  0,  0,  0,  0,  0,  0
};

int board[64];
int side_to_move = 1; // 1 = White, 0 = Black

typedef struct {
    int from;
    int to;
} Move;

void reset_board() {
    int start_board[64] = {
        B_ROOK, B_KNIGHT, B_BISHOP, B_QUEEN, B_KING, B_BISHOP, B_KNIGHT, B_ROOK,
        B_PAWN, B_PAWN,   B_PAWN,   B_PAWN,  B_PAWN, B_PAWN,   B_PAWN,   B_PAWN,
        EMPTY,  EMPTY,    EMPTY,    EMPTY,   EMPTY,  EMPTY,    EMPTY,    EMPTY,
        EMPTY,  EMPTY,    EMPTY,    EMPTY,   EMPTY,  EMPTY,    EMPTY,    EMPTY,
        EMPTY,  EMPTY,    EMPTY,    EMPTY,   EMPTY,  EMPTY,    EMPTY,    EMPTY,
        EMPTY,  EMPTY,    EMPTY,    EMPTY,   EMPTY,  EMPTY,    EMPTY,    EMPTY,
        W_PAWN, W_PAWN,   W_PAWN,   W_PAWN,  W_PAWN, W_PAWN,   W_PAWN,   W_PAWN,
        W_ROOK, W_KNIGHT, W_BISHOP, W_QUEEN, W_KING, W_BISHOP, W_KNIGHT, W_ROOK
    };
    memcpy(board, start_board, sizeof(start_board));
    side_to_move = 1;
}

// Convert square index to algebraic notation (e.g. 52 -> "e2")
void square_to_algebraic(int sq, char *str) {
    str[0] = 'a' + (sq % 8);
    str[1] = '8' - (sq / 8);
    str[2] = '\0';
}

// Convert algebraic notation to square index (e.g. "e2" -> 52)
int algebraic_to_square(const char *str) {
    int file = str[0] - 'a';
    int rank = '8' - str[1];
    return rank * 8 + file;
}

int evaluate_board() {
    int score = 0;
    for (int i = 0; i < 64; i++) {
        int piece = board[i];
        if (piece == EMPTY) continue;

        int val = PIECE_VALUES[piece];
        if (piece == W_PAWN) val += pawn_table[i];
        if (piece == B_PAWN) val += pawn_table[63 - i];

        if (piece <= W_KING) score += val;
        else score -= val;
    }
    return score;
}

int generate_moves(int is_white, Move moves[]) {
    int count = 0;
    for (int i = 0; i < 64; i++) {
        int p = board[i];
        if (p == EMPTY) continue;
        if (is_white && p > W_KING) continue;
        if (!is_white && p <= W_KING) continue;

        // Basic Pawn & Step moves
        if (p == W_PAWN && i >= 8 && board[i - 8] == EMPTY) {
            moves[count].from = i; moves[count].to = i - 8; count++;
        } else if (p == B_PAWN && i <= 55 && board[i + 8] == EMPTY) {
            moves[count].from = i; moves[count].to = i + 8; count++;
        }
    }
    return count;
}

int minimax(int depth, int alpha, int beta, int is_maximizing, Move *best_move) {
    if (depth == 0) return evaluate_board();

    Move moves[256];
    int num_moves = generate_moves(is_maximizing, moves);
    if (num_moves == 0) return evaluate_board();

    Move local_best = moves[0];

    if (is_maximizing) {
        int max_eval = -INT_MAX;
        for (int i = 0; i < num_moves; i++) {
            int captured = board[moves[i].to];
            board[moves[i].to] = board[moves[i].from];
            board[moves[i].from] = EMPTY;

            int eval = minimax(depth - 1, alpha, beta, 0, NULL);

            board[moves[i].from] = board[moves[i].to];
            board[moves[i].to] = captured;

            if (eval > max_eval) {
                max_eval = eval;
                local_best = moves[i];
            }
            if (eval > alpha) alpha = eval;
            if (beta <= alpha) break;
        }
        if (best_move) *best_move = local_best;
        return max_eval;
    } else {
        int min_eval = INT_MAX;
        for (int i = 0; i < num_moves; i++) {
            int captured = board[moves[i].to];
            board[moves[i].to] = board[moves[i].from];
            board[moves[i].from] = EMPTY;

            int eval = minimax(depth - 1, alpha, beta, 1, NULL);

            board[moves[i].from] = board[moves[i].to];
            board[moves[i].to] = captured;

            if (eval < min_eval) {
                min_eval = eval;
                local_best = moves[i];
            }
            if (eval < beta) beta = eval;
            if (beta <= alpha) break;
        }
        if (best_move) *best_move = local_best;
        return min_eval;
    }
}

// Parse GUI position command: "position startpos moves e2e4 e7e5..."
void parse_position(char *line) {
    reset_board();
    char *moves_ptr = strstr(line, "moves");
    if (moves_ptr) {
        moves_ptr += 6; // Skip "moves "
        char *token = strtok(moves_ptr, " \n");
        while (token) {
            int from = algebraic_to_square(token);
            int to = algebraic_to_square(token + 2);
            board[to] = board[from];
            board[from] = EMPTY;
            side_to_move = !side_to_move;
            token = strtok(NULL, " \n");
        }
    }
}

// Search and output the best move in UCI format: "bestmove e2e4"
void parse_go() {
    Move best_move = {0, 0};
    minimax(4, -INT_MAX, INT_MAX, side_to_move, &best_move);

    char from_str[3], to_str[3];
    square_to_algebraic(best_move.from, from_str);
    square_to_algebraic(best_move.to, to_str);

    printf("bestmove %s%s\n", from_str, to_str);
    fflush(stdout); // Crucial for GUI communication
}

// UCI Command Loop
void uci_loop() {
    char line[4096];
    setbuf(stdin, NULL);
    setbuf(stdout, NULL);

    while (fgets(line, sizeof(line), stdin)) {
        if (strncmp(line, "uci", 3) == 0) {
            printf("id name SimpleCEngine\n");
            printf("id author AI\n");
            printf("uciok\n");
        } else if (strncmp(line, "isready", 7) == 0) {
            printf("readyok\n");
        } else if (strncmp(line, "ucinewgame", 10) == 0) {
            reset_board();
        } else if (strncmp(line, "position", 8) == 0) {
            parse_position(line);
        } else if (strncmp(line, "go", 2) == 0) {
            parse_go();
        } else if (strncmp(line, "quit", 4) == 0) {
            break;
        }
        fflush(stdout);
    }
}

int main() {
    reset_board();
    uci_loop();
    return 0;
}