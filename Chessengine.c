#include <stdio.h>
#include <stdlib.h>
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

// Material values in centipawns
const int PIECE_VALUES[] = {0, 100, 320, 330, 500, 900, 20000, 100, 320, 330, 500, 900, 20000};

// Positional heatmap table for Pawns (encourages center advancement)
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

// Starting Board Array Representation
int board[64] = {
    B_ROOK, B_KNIGHT, B_BISHOP, B_QUEEN, B_KING, B_BISHOP, B_KNIGHT, B_ROOK,
    B_PAWN, B_PAWN,   B_PAWN,   B_PAWN,  B_PAWN, B_PAWN,   B_PAWN,   B_PAWN,
    EMPTY,  EMPTY,    EMPTY,    EMPTY,   EMPTY,  EMPTY,    EMPTY,    EMPTY,
    EMPTY,  EMPTY,    EMPTY,    EMPTY,   EMPTY,  EMPTY,    EMPTY,    EMPTY,
    EMPTY,  EMPTY,    EMPTY,    EMPTY,   EMPTY,  EMPTY,    EMPTY,    EMPTY,
    EMPTY,  EMPTY,    EMPTY,    EMPTY,   EMPTY,  EMPTY,    EMPTY,    EMPTY,
    W_PAWN, W_PAWN,   W_PAWN,   W_PAWN,  W_PAWN, W_PAWN,   W_PAWN,   W_PAWN,
    W_ROOK, W_KNIGHT, W_BISHOP, W_QUEEN, W_KING, W_BISHOP, W_KNIGHT, W_ROOK
};

typedef struct {
    int from;
    int to;
    int score;
} Move;

// Static Evaluation Function
int evaluate_board() {
    int score = 0;
    for (int i = 0; i < 64; i++) {
        int piece = board[i];
        if (piece == EMPTY) continue;

        int val = PIECE_VALUES[piece];
        if (piece == W_PAWN) val += pawn_table[i];
        if (piece == B_PAWN) val += pawn_table[63 - i];

        if (piece <= W_KING) {
            score += val;  // White addition
        } else {
            score -= val;  // Black subtraction
        }
    }
    return score;
}

// Generate basic pawn and step moves (Simplified move generator demo)
int generate_moves(int is_white, Move moves[]) {
    int count = 0;
    for (int i = 0; i < 64; i++) {
        int p = board[i];
        if (p == EMPTY) continue;
        if (is_white && p > W_KING) continue;
        if (!is_white && p <= W_KING) continue;

        // Simple forward pawn advance check
        if (p == W_PAWN && i >= 8 && board[i - 8] == EMPTY) {
            moves[count].from = i;
            moves[count].to = i - 8;
            count++;
        }
        else if (p == B_PAWN && i <= 55 && board[i + 8] == EMPTY) {
            moves[count].from = i;
            moves[count].to = i + 8;
            count++;
        }
    }
    return count;
}

// Minimax with Alpha-Beta Pruning Core Search
int minimax(int depth, int alpha, int beta, int is_maximizing, Move *best_move) {
    if (depth == 0) return evaluate_board();

    Move moves[256];
    int num_moves = generate_moves(is_maximizing, moves);

    if (num_moves == 0) return evaluate_board();

    if (is_maximizing) { // White turn
        int max_eval = -INT_MAX;
        for (int i = 0; i < num_moves; i++) {
            // Make move
            int captured = board[moves[i].to];
            board[moves[i].to] = board[moves[i].from];
            board[moves[i].from] = EMPTY;

            int eval = minimax(depth - 1, alpha, beta, 0, NULL);

            // Undo move
            board[moves[i].from] = board[moves[i].to];
            board[moves[i].to] = captured;

            if (eval > max_eval) {
                max_eval = eval;
                if (best_move && depth == 4) *best_move = moves[i];
            }
            if (eval > alpha) alpha = eval;
            if (beta <= alpha) break; // Alpha-Beta Cutoff
        }
        return max_eval;
    } else { // Black turn
        int min_eval = INT_MAX;
        for (int i = 0; i < num_moves; i++) {
            // Make move
            int captured = board[moves[i].to];
            board[moves[i].to] = board[moves[i].from];
            board[moves[i].from] = EMPTY;

            int eval = minimax(depth - 1, alpha, beta, 1, NULL);

            // Undo move
            board[moves[i].from] = board[moves[i].to];
            board[moves[i].to] = captured;

            if (eval < min_eval) {
                min_eval = eval;
                if (best_move && depth == 4) *best_move = moves[i];
            }
            if (eval < beta) beta = eval;
            if (beta <= alpha) break; // Alpha-Beta Cutoff
        }
        return min_eval;
    }
}

int main() {
    printf("=== Simple C Chess Engine ===\n");
    printf("Initial Evaluation Score: %d centipawns\n\n", evaluate_board());

    Move best_move;
    int depth = 4; // Search 4 half-moves ahead

    int eval = minimax(depth, -INT_MAX, INT_MAX, 1, &best_move);

    printf("Search Depth: %d ply\n", depth);
    printf("Evaluated Best Move: Square %d to Square %d\n", best_move.from, best_move.to);
    printf("Position Score after move: %d centipawns\n", eval);

    return 0;
}