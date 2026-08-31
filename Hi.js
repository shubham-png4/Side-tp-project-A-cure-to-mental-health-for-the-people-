const io = require('socket.io')(3000, { cors: { origin: "*" } });

const games = {}; // Stores room states

io.on('connection', (socket) => {
    socket.on('joinRoom', (roomId) => {
        socket.join(roomId);
        if (!games[roomId]) {
            games[roomId] = { players: [socket.id], fen: 'start' };
        } else {
            games[roomId].players.push(socket.id);
        }
    });

    socket.on('makeMove', ({ roomId, move }) => {
        // Broadcast move to opponent in the same room
        socket.to(roomId).emit('opponentMove', move);
    });
});