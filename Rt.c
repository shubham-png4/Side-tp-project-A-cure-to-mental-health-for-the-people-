#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_INPUT 512
#define COMMAND_LEN 2048

void ask_ai(const char *user_input) {
    char command[COMMAND_LEN];
    
    // Uses curl to query an open AI API endpoint
    snprintf(command, sizeof(command),
        "curl -s https://api.groq.com/openai/v1/chat/completions "
        "-H \"Authorization: Bearer %s\" "
        "-H \"Content-Type: application/json\" "
        "-d '{\"model\": \"llama3-8b-8192\", \"messages\": [{\"role\": \"user\", \"content\": \"%s\"}]}'",
        getenv("API_KEY") ? getenv("API_KEY") : "YOUR_API_KEY",
        user_input
    );

    printf("\nAI Response:\n");
    system(command);
    printf("\n\n");
}

int main() {
    char input[MAX_INPUT];

    printf("=== C AI Chatbot ===\n");
    printf("Type 'exit' to quit.\n\n");

    while (1) {
        printf("You: ");
        if (fgets(input, sizeof(input), stdin) == NULL) break;
        
        // Remove trailing newline character
        input[strcspn(input, "\n")] = 0;

        if (strcmp(input, "exit") == 0) {
            printf("Goodbye!\n");
            break;
        }

        if (strlen(input) > 0) {
            ask_ai(input);
        }
    }

    return 0;
}