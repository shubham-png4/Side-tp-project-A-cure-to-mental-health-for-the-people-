#include <stdio.h>
#include <stdlib.h>

char board[9] = {'1', '2', '3', '4', '5', '6', '7', '8', '9'};

void draw_board() {
    // Clear screen (works across Linux, macOS, and modern Windows terminals)
    printf("\033[H\033[J");
    printf("=== TIC-TAC-TOE ===\n\n");
    printf(" Player 1 (X)  -  Player 2 (O)\n\n");
    printf("     |     |     \n");
    printf("  %c  |  %c  |  %c  \n", board[0], board[1], board[2]);
    printf("_____|_____|_____\n");
    printf("     |     |     \n");
    printf("  %c  |  %c  |  %c  \n", board[3], board[4], board[5]);
    printf("_____|_____|_____\n");
    printf("     |     |     \n");
    printf("  %c  |  %c  |  %c  \n", board[6], board[7], board[8]);
    printf("     |     |     \n\n");
}

int check_win() {
    int win_conditions[8][3] = {
        {0, 1, 2}, {3, 4, 5}, {6, 7, 8}, // Rows
        {0, 3, 6}, {1, 4, 7}, {2, 5, 8}, // Columns
        {0, 4, 8}, {2, 4, 6}             // Diagonals
    };

    for (int i = 0; i < 8; i++) {
        if (board[win_conditions[i][0]] == board[win_conditions[i][1]] &&
            board[win_conditions[i][1]] == board[win_conditions[i][2]]) {
            return 1; // Winner found
        }
    }

    for (int i = 0; i < 9; i++) {
        if (board[i] != 'X' && board[i] != 'O') return 0; // Game ongoing
    }

    return -1; // Draw
}

int main() {
    int player = 1, choice, status;
    char mark;

    do {
        draw_board();
        player = (player % 2) ? 1 : 2;
        mark = (player == 1) ? 'X' : 'O';

        printf("Player %d (%c), enter a position (1-9): ", player, mark);
        if (scanf("%d", &choice) != 1) {
            while (getchar() != '\n'); // Clear invalid input
            continue;
        }

        if (choice >= 1 && choice <= 9 && board[choice - 1] != 'X' && board[choice - 1] != 'O') {
            board[choice - 1] = mark;
            status = check_win();
            if (status == 1) {
                draw_board();
                printf("🎉 Player %d (%c) wins!\n", player, mark);
                return 0;
            }
            player++;
        }
    } while (status == 0);

    draw_board();
    printf("🤝 It's a draw!\n");
    return 0;
}