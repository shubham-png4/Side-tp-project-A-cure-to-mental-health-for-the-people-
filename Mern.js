/**
 * Stockfish WebAssembly Engine Controller
 */
class StockfishEngine {
    constructor(wasmPath = 'stockfish.js') {
        // Run Stockfish inside a Web Worker so calculations don't freeze the UI
        this.worker = new Worker(wasmPath);
        this.isReady = false;
        this.onMoveCallback = null;
        this.onEvaluationCallback = null;

        this.init();
    }

    init() {
        this.worker.onmessage = (event) => {
            const line = event.data;
            this.handleEngineOutput(line);
        };

        // Initialize UCI Mode
        this.sendCommand('uci');
    }

    sendCommand(cmd) {
        this.worker.postMessage(cmd);
    }

    handleEngineOutput(line) {
        // Engine is loaded and ready
        if (line === 'uciok') {
            this.isReady = true;
            this.configureEngine();
        }

        // Parse best move output from Stockfish
        // Output format: "bestmove e2e4 ponder e7e5"
        if (line.startsWith('bestmove')) {
            const parts = line.split(' ');
            const bestMove = parts[1]; // e.g., "e2e4"
            if (this.onMoveCallback) {
                this.onMoveCallback(bestMove);
            }
        }

        // Parse real-time evaluation info
        // Output format contains: "... score cp 45 depth 18 ..." or "... score mate 3 ..."
        if (line.startsWith('info') && line.includes('score')) {
            this.parseEvaluation(line);
        }
    }

    configureEngine() {
        // Set maximum difficulty (0 to 20, where 20 = Grandmaster level)
        this.sendCommand('setoption name Skill Level value 20');
        
        // Multi-threading setting (adjust based on CPU capability)
        this.sendCommand('setoption name Threads value 2');
        
        // Hash memory allocation in MB
        this.sendCommand('setoption name Hash value 32');

        this.sendCommand('isready');
    }

    /**
     * Calculates the best move for a given FEN string
     * @param {string} fen - Current board position in FEN format
     * @param {number} depth - Search depth (e.g., 15-20 for high-level play)
     * @param {function} callback - Function called with the best move
     */
    getBestMove(fen, depth = 15, callback) {
        if (!this.isReady) {
            console.warn("Stockfish is still initializing...");
            return;
        }

        this.onMoveCallback = callback;

        // Load position into Stockfish
        this.sendCommand(`position fen ${fen}`);

        // Start search up to specified depth
        this.sendCommand(`go depth ${depth}`);
    }

    parseEvaluation(line) {
        const tokens = line.split(' ');
        const scoreIndex = tokens.indexOf('score');
        
        if (scoreIndex !== -1 && this.onEvaluationCallback) {
            const type = tokens[scoreIndex + 1]; // "cp" (centipawns) or "mate"
            const value = parseInt(tokens[scoreIndex + 2], 10);

            this.onEvaluationCallback({
                type: type, // 'cp' or 'mate'
                value: value // Centipawn score (e.g., 100 = +1.00 white advantage) or moves to mate
            });
        }
    }
}

// ==========================================
// Example Usage in app.js
// ==========================================

// 1. Initialize Stockfish Engine
const engine = new StockfishEngine('stockfish.js');

// 2. Listen for evaluation updates
engine.onEvaluationCallback = (evalData) => {
    if (evalData.type === 'cp') {
        const score = (evalData.value / 100).toFixed(2);
        console.log(`Evaluation: ${score > 0 ? '+' : ''}${score}`);
    } else if (evalData.type === 'mate') {
        console.log(`Mate in ${evalData.value}`);
    }
};

// 3. Request high-level move calculation
function calculateBotMove(currentFEN) {
    console.log("Stockfish is thinking...");
    
    // Depth 18 provides Master/Grandmaster level calculation depth
    engine.getBestMove(currentFEN, 18, (bestMove) => {
        console.log("Stockfish Best Move:", bestMove);
        
        // Parse UCI move string (e.g., "e2e4" -> from: e2, to: e4)
        const from = bestMove.substring(0, 2);
        const to = bestMove.substring(2, 4);
        
        // Execute move on your application board state
        applyMoveToBoard(from, to);
    });
}

function applyMoveToBoard(from, to) {
    // Your UI rendering and board update logic goes here
    console.log(`Executing move from ${from} to ${to}`);
}