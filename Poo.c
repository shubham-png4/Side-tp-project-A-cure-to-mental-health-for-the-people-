int minimax(int depth, int alpha, int beta, int is_maximizing, Move *best_move) {
    if (depth == 0) return evaluate_board();

    Move moves[256];
    int num_moves = generate_moves(is_maximizing, moves);
    if (num_moves == 0) return evaluate_board();

    Move local_best = moves[0];

    for (int i = 0; i < num_moves; i++) {
        // Selection sort: brings the move with highest MVV-LVA score to position 'i'
        sort_moves(moves, num_moves, i);

        // Make move
        int captured = board[moves[i].to];
        board[moves[i].to] = board[moves[i].from];
        board[moves[i].from] = EMPTY;

        int eval = minimax(depth - 1, alpha, beta, !is_maximizing, NULL);

        // Undo move
        board[moves[i].from] = board[moves[i].to];
        board[moves[i].to] = captured;

        if (is_maximizing) {
            if (eval > alpha) {
                alpha = eval;
                local_best = moves[i];
            }
        } else {
            if (eval < beta) {
                beta = eval;
                local_best = moves[i];
            }
        }

        // Alpha-Beta Cutoff
        if (beta <= alpha) {
            break; // Prune branch early thanks to MVV-LVA ordering!
        }
    }

    if (best_move) *best_move = local_best;
    return is_maximizing ? alpha : beta;
}