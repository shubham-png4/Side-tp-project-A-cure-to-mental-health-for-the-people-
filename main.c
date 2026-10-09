#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int main() {
    int secret_number, guess, attempts = 0;

    // Seed the random number generator
    srand((unsigned int)time(NULL));
    secret_number = (rand() % 100) + 1; // Number between 1 and 100

    printf("=== Guess the Number Game (C) ===\n");
    printf("I'm thinking of a number between 1 and 100.\n\n");

    do {
        printf("Enter your guess: ");
        if (scanf("%d", &guess) != 1) {
            printf("Invalid input! Please enter an integer.\n");
            while (getchar() != '\n'); // Clear input buffer
            continue;
        }

        attempts++;

        if (guess > secret_number) {
            printf("Too high! Try again.\n\n");
        } else if (guess < secret_number) {
            printf("Too low! Try again.\n\n");
        } else {
            printf("\n🎉 Congratulations! You guessed it in %d attempts!\n", attempts);
        }
    } while (guess != secret_number);

    return 0;
}
