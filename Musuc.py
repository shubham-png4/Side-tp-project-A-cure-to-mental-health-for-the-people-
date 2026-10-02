import sys
import math
import urllib.request
import os
import chess
import pygame

# Initialize Pygame & Audio Mixer
pygame.init()
pygame.mixer.init()

# --- CONFIGURATION & STYLING ---
BOARD_SIZE = 600
PANEL_WIDTH = 250
WIDTH, HEIGHT = BOARD_SIZE + PANEL_WIDTH, BOARD_SIZE
DIMENSION = 8
SQ_SIZE = BOARD_SIZE // DIMENSION
FPS = 30

# Colors
COLOR_LIGHT = (234, 235, 200)
COLOR_DARK = (119, 149, 86)
COLOR_HIGHLIGHT = (186, 202, 68)
COLOR_BG = (30, 30, 35)
COLOR_PANEL_CARD = (45, 45, 55)
COLOR_TEXT = (220, 220, 220)
COLOR_BTN = (70, 130, 180)
COLOR_BTN_HOVER = (100, 160, 210)

# --- PIECE EVALUATION & POSITIONAL TABLES ---
PIECE_VALUES = {
    chess.PAWN: 100,
    chess.KNIGHT: 320,
    chess.BISHOP: 330,
    chess.ROOK: 500,
    chess.QUEEN: 900,
    chess.KING: 20000
}

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

PST = {chess.PAWN: pawn_table, chess.KNIGHT: knight_table}


class ChessAI:
    """Minimax Engine with Alpha-Beta Pruning."""

    @staticmethod
    def evaluate_board(board: chess.Board) -> int:
        if board.is_checkmate():
            return -99999 if board.turn == chess.WHITE else 99999
        if board.is_stalemate() or board.is_insufficient_material():
            return 0

        score = 0
        for square in chess.SQUARES:
            piece = board.piece_at(square)
            if piece:
                val = PIECE_VALUES[piece.piece_type]
                pst_val = PST.get(piece.piece_type, [0]*64)[square if piece.color == chess.WHITE else chess.square_mirror(square)]
                total = val + pst_val
                score += total if piece.color == chess.WHITE else -total
        return score

    @classmethod
    def minimax(cls, board: chess.Board, depth: int, alpha: float, beta: float, maximizing_player: bool):
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


class MusicPlayer:
    """Manages background music playlist and audio controls."""

    def __init__(self):
        self.playlist = [
            {"title": "Canon in D", "url": "[https://archive.org/download/Favourite-Classics/A07.Canon.ogg](https://archive.org/download/Favourite-Classics/A07.Canon.ogg)"},
            {"title": "Clair de Lune", "url": "[https://archive.org/download/peaceful-classics/008%20GABRIEL%20FAUR%C3%89%20-%20Pie%20Jesu%20from%20Gabriel%20Faure%27s%20Requiem%2C%20Op.%2048%3A%204..mp3](https://archive.org/download/peaceful-classics/008%20GABRIEL%20FAUR%C3%89%20-%20Pie%20Jesu%20from%20Gabriel%20Faure%27s%20Requiem%2C%20Op.%2048%3A%204..mp3)"},
            {"title": "Peer Gynt - Morning", "url": "[https://archive.org/download/Favourite-Classics/B04.Morning%20From%20%27Peer%20Gynt%27%20Suite%20No%201.ogg](https://archive.org/download/Favourite-Classics/B04.Morning%20From%20%27Peer%20Gynt%27%20Suite%20No%201.ogg)"}
        ]
        self.current_idx = 0
        self.is_playing = False
        self.volume = 0.5
        pygame.mixer.music.set_volume(self.volume)

    def load_track(self, index: int):
        track = self.playlist[index]
        filename = f"track_{index}.ogg"
        
        # Download stream locally if not cached
        if not os.path.exists(filename):
            try:
                print(f"[+] Downloading track: {track['title']}...")
                urllib.request.urlretrieve(track["url"], filename)
            except Exception as e:
                print(f"[-] Failed to download track: {e}")
                return False

        try:
            pygame.mixer.music.load(filename)
            pygame.mixer.music.play(-1)  # Loop indefinitely
            self.is_playing = True
            return True
        except Exception as e:
            print(f"[-] Audio playback error: {e}")
            return False

    def toggle_play(self):
        if not self.is_playing:
            if not pygame.mixer.music.get_busy():
                self.load_track(self.current_idx)
            else:
                pygame.mixer.music.unpause()
            self.is_playing = True
        else:
            pygame.mixer.music.pause()
            self.is_playing = False

    def next_track(self):
        self.current_idx = (self.current_idx + 1) % len(self.playlist)
        self.load_track(self.current_idx)

    def adjust_volume(self, delta: float):
        self.volume = max(0.0, min(1.0, self.volume + delta))
        pygame.mixer.music.set_volume(self.volume)


class ChessApp:
    """Main Application managing Chess GUI and Music Sidebar."""

    def __init__(self):
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        pygame.display.set_caption("Relaxing Chess & Music Player")
        self.clock = pygame.time.Clock()
        self.board = chess.Board()
        self.selected_square = None
        
        self.music = MusicPlayer()
        self.font_piece = pygame.font.SysFont("Helvetica", SQ_SIZE // 2, bold=True)
        self.font_ui = pygame.font.SysFont("Arial", 16, bold=True)
        self.font_title = pygame.font.SysFont("Arial", 18, bold=True)

        self.piece_unicode = {
            'R': '♖', 'N': '♘', 'B': '♗', 'Q': '♕', 'K': '♔', 'P': '♙',
            'r': '♜', 'n': '♞', 'b': '♝', 'q': '♛', 'k': '♚', 'p': '♟'
        }

        # Automatically start background track
        self.music.load_track(0)

    def draw_board(self):
        """Draws chessboard."""
        for r in range(DIMENSION):
            for c in range(DIMENSION):
                color = COLOR_LIGHT if (r + c) % 2 == 0 else COLOR_DARK
                square = chess.square(c, 7 - r)

                if self.selected_square == square:
                    color = COLOR_HIGHLIGHT

                pygame.draw.rect(self.screen, color, pygame.Rect(c * SQ_SIZE, r * SQ_SIZE, SQ_SIZE, SQ_SIZE))

    def draw_pieces(self):
        """Renders unicode chess pieces."""
        for square in chess.SQUARES:
            piece = self.board.piece_at(square)
            if piece:
                col = chess