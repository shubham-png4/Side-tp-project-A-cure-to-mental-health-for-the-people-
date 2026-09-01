#include <stdio.h>
#include <stdlib.h>

typedef struct {
    int from;
    int to;
    int score; // Sort weight for move ordering
} Move;

// Convert piece IDs (1..12) into piece type indices (1..6)
int get_piece_type(int piece) {
    if (piece == EMPTY) return 0;
    return (piece <= W_KING) ? piece : (piece - 6);
}

// Score moves during generation using MVV-LVA
int generate_moves(int is_white, Move moves[]) {
    int count = 0;
    for (int i = 0; i < 64; i++) {
        int p = board[i];
        if (p == EMPTY) continue;
        if (is_white && p > W_KING) continue;
        if (!is_white && p <= W_KING) continue;

        int attacker = get_piece_type(p);

        // Standard Pawn advance example
        int fwd = is_white ? (i - 8) : (i + 8);
        if (fwd >= 0 && fwd < 64 && board[fwd] == EMPTY) {
            moves[count].from = i;
            moves[count].to = fwd;
            moves[count].score = 0; // Quiet moves scored low
            count++;
        }

        // Capture generation (Example checking diagonal squares)
        int caps[2] = {is_white ? i - 9 : i + 7, is_white ? i - 7 : i + 9};
        for (int c = 0; c < 2; c++) {
            int target_sq = caps[c];
            if (target_sq >= 0 && target_sq < 64) {
                int victim_piece = board[target_sq];
                if (victim_piece != EMPTY) {
                    int victim = get_piece_type(victim_piece);
                    // Ensure opponent piece
                    if ((is_white && victim_piece > W_KING) || (!is_white && victim_piece <= W_KING)) {
                        moves[count].from = i;
                        moves[count].to = target_sq;
                        moves[count].score = mvv_lva_scores[attacker][victim] + 10000; // Boost captures
                        count++;
                    }
                }
            }
        }
    }
    return count;
}

// Selection Sort pass to pick highest scoring move next
void sort_moves(Move moves[], int count, int current_index) {
    int best_index = current_index;
    for (int j = current_index + 1; j < count; j++) {
        if (moves[j].score > moves[best_index].score) {
            best_index = j;
        }
    }
    if (best_index != current_index) {
        Move temp = moves[current_index];
        moves[current_index] = moves[best_index];
        moves[best_index] = temp;
    }
}