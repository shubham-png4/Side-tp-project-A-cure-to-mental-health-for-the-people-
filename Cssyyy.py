import sys
import math
import chess
import pygame

# Initialize Pygame
pygame.init()

# --- CONSTANTS & CONFIGURATION ---
WIDTH, HEIGHT = 600, 600
DIMENSION = 8
SQ_SIZE = WIDTH // DIMENSION
FPS = 30

# Colors (Modern Charcoal & Soft Mint Theme)
COLOR_LIGHT = (234, 235, 200)
COLOR_DARK = (119, 149, 86)
COLOR_HIGHLIGHT = (186, 202, 68)
COLOR_TEXT = (40, 40, 40)

# --- PIECE EVALUATION TABLES (Positional Intelligence) ---
# Piece values
PIECE_VALUES = {
    chess.PAWN: 100,
    chess.KNIGHT: 320,
    chess.BISHOP: 330,
    chess.ROOK: 500,
    chess.QUEEN: 900,
    chess.KING: 20000
}

# Piece-Square Tables (Encourages positional control, e.g., pawns pushing center, knights in middle)
pawn_table = [
     0,  0,  0,  0,  0,  0,  0,  0,
    50, 50, 50, 50, 50, 50, 50, 50,
    10, 10, 20, 30, 30, 20, 10, 10,
     5,  5, 10, 25, 25, 10,  5,  5,
     0,  0,  0, 20, 20,  0,  0,  0,
     5, -5,-10,  0,  0,-10, -5,  5,
     5, 10, 10,-20,-20, 10, 10,  5,
     0,  0,  0,  0,  0,  0,  0,  0
]

knight_table = [
    -50,-40,-30,-30,-30,-30,-40,-50,
    -40,-20,  0,  0,  0,  0,-20,-40,
    -30,  0, 10, 15, 15, 10,  0,-30,
    -30,  5, 15, 20, 20, 15,  5,-30,
    -30,  0, 15, 20, 20, 15,  0,-30,
    -30,  5, 10, 15, 15, 10,  5,-30,
    -40,-20,  0,  5,  5,  0,-20,-40,
    -50,-40,-30,-30,-30,-30,-40,-50,
]

PST = {
    chess.PAWN: pawn_table,
    chess.KNIGHT: knight_table,
}


class ChessAI:
    """Minimax AI engine with Alpha-Beta Pruning and Positional Evaluation."""

    @staticmethod
    def evaluate_board(board: chess.Board) -> int:
        if board.is_checkmate():
            if board.turn == chess.WHITE:
                return -99999  # Black wins
            return 99999      # White wins
        if board.is_stalemate() or board.is_insufficient_material():
            return 0

        score = 0
        for square in chess.SQUARES:
            piece = board.piece_at(square)
            if piece:
                val = PIECE_VALUES[piece.piece_type]
                # Add positional bias if defined
                pst_val = PST.get(piece.piece_type, [0]*64)[square if piece.color == chess.WHITE else chess.square_mirror(square)]
                total_val = val + pst_val

                if piece.color == chess.WHITE:
                    score += total_val
                else:
                    score -= total_val
        return score

    @classmethod
    def minimax(cls, board: chess.Board, depth: int, alpha: float, beta: float, maximizing_player: bool) -> tuple[float, chess.Move | None]:
        if depth == 0 or board.is_game_over():
            return cls.evaluate_board(board), None

        best_move = None
        legal_moves = list(board.legal_moves)

        if maximizing_player:
            max_eval = -math.inf
            for move in legal_moves:
                board.push(move)
                eval_score, _ = cls.minimax(board, depth - 1, alpha, beta, False)
                board.pop()
                if eval_score > max_eval:
                    max_eval = eval_score
                    best_move = move
                alpha = max(alpha, eval_score)
                if beta <= alpha:
                    break
            return max_eval, best_move
        else:
            min_eval = math.inf
            for move in legal_moves:
                board.push(move)
                eval_score, _ = cls.minimax(board, depth - 1, alpha, beta, True)
                board.pop()
                if eval_score < min_eval:
                    min_eval = eval_score
                    best_move = move
                beta = min(beta, eval_score)
                if beta <= alpha:
                    break
            return min_eval, best_move


class ChessGUI:
    """Handles Pygame board rendering, piece drawing, and user interactions."""

    def __init__(self):
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        pygame.display.set_caption("Python AI Chess")
        self.clock = pygame.time.Clock()
        self.board = chess.Board()
        self.selected_square = None
        self.font = pygame.font.SysFont("Helvetica", SQ_SIZE // 2, bold=True)

        # Unicode mapping for piece rendering (no external image files required)
        self.piece_unicode = {
            'R': '♖', 'N': '♘', 'B': '♗', 'Q': '♕', 'K': '♔', 'P': '♙',
            'r': '♜', 'n': '♞', 'b': '♝', 'q': '♛', 'k': '♚', 'p': '♟'
        }

    def draw_board(self):
        """Draws the 8x8 chessboard and highlights the selected square."""
        for r in range(DIMENSION):
            for c in range(DIMENSION):
                color = COLOR_LIGHT if (r + c) % 2 == 0 else COLOR_DARK
                square = chess.square(c, 7 - r)

                if self.selected_square == square:
                    color = COLOR_HIGHLIGHT

                pygame.draw.rect(self.screen, color, pygame.Rect(c * SQ_SIZE, r * SQ_SIZE, SQ_SIZE, SQ_SIZE))

    def draw_pieces(self):
        """Renders pieces using Unicode characters."""
        for square in chess.SQUARES:
            piece = self.board.piece_at(square)
            if piece:
                col = chess.square_file(square)
                row = 7 - chess.square_rank(square)

                symbol = self.piece_unicode[piece.symbol()]
                # White pieces render light gray, Black pieces render dark charcoal
                text_color = (255, 255, 255) if piece.color == chess.WHITE else (20, 20, 20)

                text_surface = self.font.render(symbol, True, text_color)
                text_rect = text_surface.get_rect(center=(col * SQ_SIZE + SQ_SIZE // 2, row * SQ_SIZE + SQ_SIZE // 2))
                self.screen.blit(text_surface, text_rect)

    def run(self):
        running = True
        player_turn = True  # True = Human (White), False = AI (Black)
        ai_depth = 3        # Search depth (3 = Fast & Smart; 4 = Very Smart but slower)

        while running:
            self.draw_board()
            self.draw_pieces()
            pygame.display.flip()

            # Handle AI turn
            if not player_turn and not self.board.is_game_over():
                pygame.display.set_caption("AI is thinking...")
                _, ai_move = ChessAI.minimax(self.board, depth=ai_depth, alpha=-math.inf, beta=math.inf, maximizing_player=False)
                if ai_move:
                    self.board.push(ai_move)
                player_turn = True
                pygame.display.set_caption("Python AI Chess")

            # Handle Event Loop
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False

                elif event.type == pygame.MOUSEBUTTONDOWN and player_turn and not self.board.is_game_over():
                    col = event.pos[0] // SQ_SIZE
                    row = 7 - (event.pos[1] // SQ_SIZE)
                    clicked_square = chess.square(col, row)

                    if self.selected_square is None:
                        # Select piece if it belongs to White
                        piece = self.board.piece_at(clicked_square)
                        if piece and piece.color == chess.WHITE:
                            self.selected_square = clicked_square
                    else:
                        # Attempt move
                        move = chess.Move(self.selected_square, clicked_square)
                        # Check for pawn promotion
                        if chess.Move(self.selected_square, clicked_square, promotion=chess.QUEEN) in self.board.legal_moves:
                            move = chess.Move(self.selected_square, clicked_square, promotion=chess.QUEEN)

                        if move in self.board.legal_moves:
                            self.board.push(move)
                            player_turn = False
                        
                        self.selected_square = None

            self.clock.tick(FPS)

        pygame.quit()
        sys.exit()


if __name__ == "__main__":
    game = ChessGUI()
    game.run()