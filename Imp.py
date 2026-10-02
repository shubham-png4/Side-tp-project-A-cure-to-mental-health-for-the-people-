import sys
import math
import urllib.request
import io
import chess
import pygame

# Initialize Pygame and Mixer
pygame.init()
pygame.mixer.init()

# --- CONFIGURATION & DIMENSIONS ---
CHESS_SIZE = 600
PANEL_WIDTH = 300
WIDTH = CHESS_SIZE + PANEL_WIDTH
HEIGHT = CHESS_SIZE
DIMENSION = 8
SQ_SIZE = CHESS_SIZE // DIMENSION
FPS = 30

# Theme Colors (Modern Dark Slate & Mint)
COLOR_LIGHT = (234, 235, 200)
COLOR_DARK = (119, 149, 86)
COLOR_HIGHLIGHT = (186, 202, 68)
PANEL_BG = (30, 32, 40)
PANEL_CARD = (42, 45, 58)
ACCENT_GREEN = (100, 200, 120)
TEXT_LIGHT = (230, 230, 230)
TEXT_MUTED = (150, 155, 170)

# --- PUBLIC STREAMING SOOTHING MUSIC TRACKS ---
TRACKS = [
    {
        "title": "Moonlight Sonata",
        "artist": "Beethoven (Peaceful Piano)",
        "url": "https://ia800201.us.archive.org/21/items/Favourite-Classics/A02.Clarinet%20Concerto%202nd%20Movement.ogg"
    },
    {
        "title": "Canon in D",
        "artist": "Pachelbel (Calm Chamber)",
        "url": "https://ia800201.us.archive.org/21/items/Favourite-Classics/A07.Canon.ogg"
    },
    {
        "title": "Air on the G String",
        "artist": "J.S. Bach (Soothing Strings)",
        "url": "https://ia800201.us.archive.org/21/items/Favourite-Classics/B06.Adagio.ogg"
    }
]

# --- AI POSITIONAL TABLES ---
PIECE_VALUES = {
    chess.PAWN: 100, chess.KNIGHT: 320, chess.BISHOP: 330,
    chess.ROOK: 500, chess.QUEEN: 900, chess.KING: 20000
}

PST_PAWN = [
     0,  0,  0,  0,  0,  0,  0,  0,
    50, 50, 50, 50, 50, 50, 50, 50,
    10, 10, 20, 30, 30, 20, 10, 10,
     5,  5, 10, 25, 25, 10,  5,  5,
     Here is the updated Python script integrating a **built-in background music player** directly into the Pygame Chess GUI. 

It uses Pygame's `mixer` module to handle audio playback and provides interactive controls on the side panel to **Play/Pause**, **Skip Tracks**, and **Adjust Volume** while you play against the AI engine.

---

### Prerequisites

Ensure you have `pygame` and `python-chess` installed:

```bash
pip install pygame python-chess