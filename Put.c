// MVV-LVA score matrix [Attacker][Victim]
// Rows: Attacker (1: Pawn ... 6: King)
// Columns: Victim (1: Pawn ... 6: King)
static const int mvv_lva_scores[7][7] = {
    {0,   0,   0,   0,   0,   0,   0}, // Victim = EMPTY
    {0, 105, 205, 305, 405, 505, 605}, // Attacker = PAWN (P x P=105, P x Q=505)
    {0, 104, 204, 304, 404, 504, 604}, // Attacker = KNIGHT
    {0, 103, 203, 303, 403, 503, 603}, // Attacker = BISHOP
    {0, 102, 202, 302, 402, 502, 602}, // Attacker = ROOK
    {0, 101, 201, 301, 401, 501, 601}, // Attacker = QUEEN
    {0, 100, 200, 300, 400, 500, 600}  // Attacker = KING
};