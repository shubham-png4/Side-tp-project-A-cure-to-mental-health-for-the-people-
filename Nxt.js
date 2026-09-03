// server.js
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });

app.use(express.static('public'));

const rooms = {};      // { roomId: { players: [], boardState: '' } }
const tournaments = {};// { tourneyId: { players: [], brackets: [] } }

io.on('connection', (socket) => {
    console.log(`User Connected: ${socket.id}`);

    // --- GLOBAL MULTIPLAYER ---
    socket.on('join_room', (roomId) => {
        socket.join(roomId);
        if (!rooms[roomId]) {
            rooms[roomId] = { players: [socket.id] };
            socket.emit('player_assigned', 'w');
        } else if (rooms[roomId].players.length === 1) {
            rooms[roomId].players.push(socket.id);
            socket.emit('player_assigned', 'b');
            io.to(roomId).emit('game_start', { roomId });
        } else {
            socket.emit('room_full');
        }
    });

    socket.on('make_move', ({ roomId, move }) => {
        socket.to(roomId).emit('receive_move', move);
    });

    // --- TOURNAMENT MODE ---
    socket.on('create_tournament', (tName) => {
        const tId = 't_' + Math.random().toString(36).substring(2, 7);
        tournaments[tId] = { name: tName, players: [socket.id] };
        socket.emit('tournament_created', { tId, tName });
    });

    socket.on('join_tournament', (tId) => {
        if (tournaments[tId]) {
            tournaments[tId].players.push(socket.id);
            io.emit('tournament_update', tournaments[tId]);
        }
    });

    socket.on('disconnect', () => {
        console.log(`User Disconnected: ${socket.id}`);
    });
});

server.listen(3000, () => console.log('Chess Server running on http://localhost:3000'));