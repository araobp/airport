# Agentic AI Implementation (Schematic)

This document outlines the architecture of the agentic AI implemented in the Godot Airport project. The system uses direct node references, function calls, a ReAct loop, and distinct memory systems to allow a Gemini-based agent to interact with the simulation.

## The Roles of MCP Client and MCP Server

In this project, `MCP Client` and `MCP Server` are **conceptual roles**, not literal network components. They define a clear separation between the AI's decision-making logic and the game's action-execution logic.

### MCP Server (The Tool Provider)

*   **What it is:** An "MCP Server" is any Godot node that groups together a set of related functions (tools) that can be executed by the AI. 
*   **Example:** The `airport_services.gd` node is a concrete example of a component fulfilling the MCP Server role.

### MCP Client (The Tool Consumer)

*   **What it is:** The "MCP Client" is the single entity that consumes the tools provided by all MCP Servers. 
*   **Example:** The `gemini.gd` node is the component that fulfills the MCP Client role.

## Memory Implementation

The agent utilizes both short-term and long-term memory to maintain context and access knowledge.

### Short-Term Memory (Conversational History)

*   **Implementation:** A `chat_history` array within the `gemini.gd` script.
*   **Function:** This array stores a running log of the current conversation, including user queries, model text responses, tool calls, and the results (observations) from those tool calls. It provides the immediate context necessary for the agent to understand follow-up questions and the results of its own actions within a ReAct loop.

### Long-Term Memory (Knowledge Base)

*   **Implementation:** The `locations.json` file.
*   **Function:** This file acts as a static, long-term knowledge base for the agent, specifically focused on Location-Based Services (LBS). It provides the agent with persistent information about points of interest within the airport (e.g., gates, shops, restrooms). The agent can reference this data to answer questions about locations without needing to discover them dynamically.

## ReAct Loop Implementation

The system implements a **ReAct (Reason-Act)** loop, enabling the agent to perform multi-step tasks.

1.  **Reason:** The `Gemini Script` sends the user's query and the short-term memory (chat history) to the Gemini model.
2.  **Act:** If a tool is needed, the model's API response includes a `functionCall`. The `Gemini Script` executes this function.
3.  **Observe:** The executed function returns a result, which is the "Observation".
4.  **Repeat:** The observation is added to the short-term memory, and the loop repeats by sending the updated history back to the model.

## High-Level Architecture

```text
+-------------------+   (Direct Node Reference)   +-----------------+   (HTTP Request)   +----------------+
|   Chat Window     |---------------------------->|  Gemini Script  |------------------->|   Gemini API   |
| (gets user input) |                             |  (MCP Client)   |                    |   (External)   |
+-------------------+                             +-----------------+                    +----------------+
                                                          |
                                                          | (Executes Tool via Callable)
                                                          v
                                                  +----------------------------+
                                                  |   Any Tool Provider        |
                                                  | (e.g. airport_services.gd) |
                                                  | (Conceptual MCP Server)    |
                                                  +----------------------------+
```

## Data Flow: Step-by-Step

1.  **USER INPUT:** User types a command in the `Chat Window`.
2.  **SEND COMMAND:** A controller calls the `gemini.chat()` function on the `Gemini Script` (the MCP Client).
3.  **INVOKE API (Reason):** The `Gemini Script` sends the command and the short-term memory to the Gemini API.
4.  **AGENT DECISION (Act):** The Gemini API returns a `functionCall`.
5.  **PARSE & EXECUTE (Observe):** The `Gemini Script` (MCP Client) parses the function call, looks up the correct MCP Server node, and executes the function using a `Callable`. The return value is the observation.
6.  **SIMULATION UPDATE:** The function on the MCP Server node runs, manipulating the Godot scene.
7.  **REPEAT or FINISH:** The observation is added to short-term memory. If the task requires more steps, the script repeats from step 3. Otherwise, the model returns a final text response.
