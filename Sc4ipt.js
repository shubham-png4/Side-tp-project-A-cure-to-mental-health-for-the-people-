// public/app.js
const socket = io();
const game = new Chess();

let currentMode = 'local';
let playerColor = 'w';
let selectedSq = null;
let roomId = null;

// Tactical Puzzles Database
const puzzles = [
    { fen: "r1bqkb1r/pppp1ppp/2n5/4p3/2B1n3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 4", move: "c4f7", hint: "Look for a king sacrifice check!" },
    { fen: "6k1/5ppp/8/8/8/8/8/1R4K1 w - - 0 1", move: "b1b8", hint: "Back-rank checkmate opportunity." }
];
let currentPuzzleIdx = 0;

function setMode(mode) {
    currentMode = mode;
    game.reset();
    selectedSq = null;
    document.getElementById('coach-box').style.display = mode === 'coach' ? 'block' : 'none';
    document.getElementById('mode-title').innerText = mode.toUpperCase() + " MODE";
    
    const controls = document.getElementById('mode-controls');
    controls.innerHTML = '';

    if (mode === 'multiplayer') {
        controls.innerHTML = `
            <input type="text" id="room-input" placeholder="Room ID (e.g. room123)" style="padding: 6px; width: 60%;">
            <button onclick="joinMultiplayer()">Join</button>
        `;
    } else if (mode === 'puzzles') {
        loadPuzzle(currentPuzzleIdx);
    } else if (mode === 'bot') {
        controls.innerHTML = `
            <label>Bot Level: </label>
            <select id="bot-level">
                <option value="1">Easy (Random)</option>
                <option value="2">Medium (Captures)</option>
            </select>
        `;
    } else if (mode === 'tournament') {
        controls.innerHTML = `
            <button onclick="socket.emit('create_tournament', 'Global Masters')">Create Tournament</button>
        `;
    }
    renderBoard();
}

function renderBoard() {
    const boardEl = document.getElementById('board');
    boardEl.innerHTML = '';
    const boardState = game.board();

    for (let r = 0; r < 8; r++) {
        for (let c = 0; c < 8; c++) {
            const sqEl = document.createElement('div');
            const sqName = String.fromCharCode(97 + c) + (8 - r);
            const isWhiteSq = (r + c) % 2 === 0;

            sqEl.className = `sq ${isWhiteSq ? 'white' : 'black'}`;
            if (selectedSq === sqName) sqEl.classList.add('selected');

            const piece = boardState[r][c];
            if (piece) {
                sqEl.innerText = getPieceSymbol(piece);
            }

            sqEl.onclick = () => handleSquareClick(sqName);
            boardEl.appendChild(sqEl);
        }
    }
    document.getElementById('status').innerText = `Turn: ${game.turn() === 'w' ? 'White' : 'Black'}`;
}

function getPieceSymbol(piece) {
    const symbols = {
        p: '♟', r: '♜', n: '♞', b: '♝', q: '♛', k: '♚',
        P: '♙', R: '♖', N: '♘', B: '♗', Q: '♕', K: '♔'
    };
    return piece.color === 'w' ? symbols[piece.type.toUpperCase()] : symbols[piece.type];
}

function handleSquareClick(sq) {
    // Prevent moving opponent pieces in Online Multiplayer
    if (currentMode === 'multiplayer' && game.turn() !== playerColor) return;

    if (!selectedSq) {
        if (game.get(sq) && game.get(sq).color === game.turn()) {
            selectedSq = sq;
        }
    } else {
        const move = game.move({ from: selectedSq, to: sq, promotion: 'q' });
        selectedSq = null;

        if (move) {
            renderBoard();

            // Handle Mode Specific Actions
            if (currentMode === 'multiplayer') {
                socket.emit('make_move', { roomId, move });
            } else if (currentMode === 'bot' && !game.game_over()) {
                setTimeout(makeBotMove, 400);
            } else if (currentMode === 'coach') {
                runCoachAnalysis(move);
            } else if (currentMode === 'puzzles') {
                checkPuzzleMove(move);
            }
        }
    }
    renderBoard();
}

// --- MULTIPLAYER SOCKET EVENTS ---
function joinMultiplayer() {
    roomId = document.getElementById('room-input').value;
    if (roomId) socket.emit('join_room', roomId);
}

socket.on('player_assigned', (color) => {
    playerColor = color;
    alert(`Joined as ${color === 'w' ? 'White' : 'Black'}`);
});

socket.on('receive_move', (move) => {
    game.move(move);
    renderBoard();
});

// --- PUZZLE ENGINE ---
function loadPuzzle(idx) {
    game.load(puzzles[idx].fen);
    document.getElementById('status').innerText = `Puzzle #${idx + 1}: Find the winning move!`;
    document.getElementById('coach-box').style.display = 'block';
    document.getElementById('coach-box').innerText = `Hint: ${puzzles[idx].hint}`;
    renderBoard();
}

function checkPuzzleMove(move) {
    const moveStr = move.from + move.to;
    if (moveStr === puzzles[currentPuzzleIdx].move) {
        alert("Correct! Puzzle Solved!");
        currentPuzzleIdx = (currentPuzzleIdx + 1) % puzzles.length;
        loadPuzzle(currentPuzzleIdx);
    } else {
        alert("Wrong move! Try again.");
        game.undo();
        renderBoard();
    }
}

// --- AI COACH MODE ---
function runCoachAnalysis(move) {
    const coachBox = document.getElementById('coach-box');
    if (move.captured) {
        coachBox.innerText = `Great tactical trade! You captured a ${move.captured.toUpperCase()}.`;
    } else if (move.piece === 'p' && (move.to.includes('d4') || move.to.includes('e4'))) {
        coachBox.innerText = `Solid opening move! Occupying the center gives you board control.`;
    } else {
        coachBox.innerText = `Move recorded. Always check if your pieces are defended properly.`;
    }
}

// --- BOT AI MODE ---
function makeBotMove() {
    const moves = game.moves({ verbose: true });
    if (moves.length === 0) return;

    // Level 2: Simple Capture Prioritization
    let selectedMove = moves[Math.floor(Math.random() * moves.length)];
    const captures = moves.filter(m => m.captured);
    if (captures.length > 0) selectedMove = captures[0];

    game.move(selectedMove);
    renderBoard();
}

// Initial setup
setMode('local');