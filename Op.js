// Client listens for incoming opponent moves
socket.on('opponentMove', (move) => {
    game.move(move); // Apply move to local board library (e.g., chess.js)
    board.position(game.fen()); // Update UI board
});

// Client sends move after validation
function onDrop(source, target) {
    const move = game.move({ from: source, to: target, promotion: 'q' });
    if (move === null) return 'snapback';
    
    socket.emit('makeMove', { roomId: currentRoom, move: move });
}