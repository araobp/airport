# Agentic AI Implementation

This document outlines the implementation of the agentic AI in the Smart Airport simulation. The agent's architecture is based on the **ReAct (Reasoning and Acting)** framework, which enables the AI to reason about its tasks, create plans, and execute them by interacting with the environment.

## Core Components

*   **Gemini AI Model:** The core of the agent's intelligence, responsible for natural language understanding, reasoning, and decision-making.
*   **McpServer (`mcp_server.gd`):** The "brain" of the agent in the Godot simulation. It hosts the Gemini client, manages the conversation history, and defines the tools (functions) that the AI can use to interact with the environment.
*   **McpClient (`mcp_client.gd`):** Represents the user-facing interface to the AI. It captures user input (text and images), sends it to the `McpServer`, and displays the AI's responses. It simulates a wearable device.
*   **Tools:** A set of functions that the AI can call to perform actions or retrieve information. These are defined in `mcp_server.gd` and exposed to the Gemini model through the function calling feature.

## The ReAct Loop

The agent operates in a continuous loop, similar to the ReAct framework:

1.  **Observe:** The `McpClient` captures the user's input (text and/or image) and sends it to the `McpServer`.
2.  **Think:** The `McpServer` sends the user's input, along with the conversation history, to the Gemini model. The model analyzes the input, reasons about the user's intent, and decides on a course of action. This might involve generating a text response, calling one or more tools, or a combination of both.
3.  **Act:** If the model decides to call a tool, the `McpServer` executes the corresponding function and sends the result back to the model. If the model generates a text response, the `McpServer` sends it to the `McpClient` to be displayed to the user.

This iterative process of action, observation, and thought allows the agent to learn from its interactions with the environment and refine its behavior over time.

## Dynamic Guideline Generation

A key challenge for AI agents is handling complex, multi-step user requests that may not have a pre-defined tool or function. To address this, this project implements a dynamic guideline generation service.

### Motivation

Instead of hard-coding the logic for every possible complex request, the agent can be prompted to generate its own guidelines for how to approach the problem. This is a form of meta-cognition, where the agent reasons about its own problem-solving process.

### Implementation

The `mcp_server.gd` script includes a `generate_guidelines` tool. When the user asks the AI to generate guidelines for a specific request, this tool is called. The current implementation uses a dummy function that returns a pre-defined set of guidelines. However, it is designed with the future possibility of calling a "meta-level" AI to generate these guidelines dynamically.

The generated guidelines are stored in `airport/mcp_server_memory/guidelines.txt` and loaded into a global variable, making them accessible to the agent for subsequent interactions.

### Example Workflow

1.  **User:** "I want to book a flight, find a hotel, and arrange for a rental car. Can you help me with that?"
2.  **AI (to itself):** This is a complex request. I should generate guidelines to handle it.
3.  **AI (calls tool):** `generate_guidelines(request="Book a flight, find a hotel, and arrange for a rental car.")`
4.  **System:** Generates and stores guidelines (e.g., 1. Find flights, 2. Find hotels, 3. Find rental cars, 4. Confirm with user).
5.  **AI (to user):** "I can help with that. I will first search for flights. What is your destination and travel dates?"
...and so on, following the generated guidelines.

This capability significantly enhances the agent's autonomy and flexibility, allowing it to tackle a wider range of complex tasks.