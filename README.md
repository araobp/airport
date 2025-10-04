# Airport: A Smart Airport Simulation

[![Godot Engine](https://img.shields.io/badge/Godot-4.4-blue.svg)](https://godotengine.org)
[![Gemini AI](https://img.shields.io/badge/AI-Gemini-purple.svg)](https://ai.google.dev/)

***Work in progress***

This project is a work-in-progress simulation of a "smart airport" environment, showcasing the power of AI, particularly Google's Gemini model, to create interactive and intelligent experiences. The simulation is built using the Godot Engine.

## Screenshots

<table>
  <tr>
    <td>
      <img src="docs/airport_smartkeys.jpg" width="600">
    </td>
    <td>
      <img src="docs/airport_smartglasses2.jpg" width="600">
    </td>
  </tr>
  <tr>
    <td>
      <img src="docs/screenshots/Screenshot 2025-09-15 at 22.12.50.jpg" width="600">
    </td>
    <td>
      <img src="docs/screenshots/Screenshot 2025-09-15 at 22.13.45.jpg" width="600">
    </td>
  </tr>
</table>

## Features

*   **AI-Powered Chat:** Interact with the airport environment using natural language through a chat interface powered by the Gemini AI model.
*   **Multimodal Input:** The AI can "see" and understand the environment through image captures from the player's viewpoint.
*   **Function Calling:** The AI can interact with the simulation by calling functions to perform actions like opening doors.
*   **Dynamic Location Learning:** The AI learns the locations of amenities in the airport through visual-based interaction and data logging.
*   **Security Robot:** A security robot patrols the airport, providing an additional layer of security and interaction.
*   **Network Graph Generation:** Generate a network graph to visualize the relationships between visitors, zones, and amenities.
*   **Web-Based Visualization:** View the generated network graph in an interactive web-based viewer built with SvelteKit.
*   **Support for Multiple Visitors:** Switch between different visitor perspectives and interact with the AI from each.
*   **Dynamic Guideline Generation:** The AI can generate guidelines on how to handle complex user requests, enhancing its problem-solving capabilities.

## Architecture

<img src="docs/Airport Services.jpg" width="700">

## Getting Started

### Prerequisites

*   Godot Engine (version 4.5 or later)
*   A Gemini API key
*   Node.js and npm (for the viewer)

### API Key Management

To use the AI features, you need to provide a Gemini API key. Create a file named `gemini_api_key_env.txt` in the `airport` directory and place your Gemini API key in it.

**`gemini_api_key_env.txt`:**
```
YOUR_GEMINI_API_KEY
```

This file is listed in `.gitignore` and will not be committed to version control. The application will automatically read the key from this file.

## AI-Powered Airport

This simulation showcases a variety of AI-powered features that create a dynamic and interactive airport environment.

### AI Agent Implementation

The core of the smart airport is the AI agent, powered by the Gemini model. It interacts with the environment using natural language and visual input. For a detailed explanation of the agent's architecture, including the ReAct loop and memory systems, please see the [Agentic AI Implementation](docs/AGENTIC_AI.md) document.

### Security Robot

A security robot patrols the airport, providing an additional layer of security and interaction. The `security_robot.gd` script defines the robot's behavior, which is based on a predefined path of markers. The robot moves from one marker to the next, and when it reaches the end of the path, it reverses direction, creating a continuous patrol loop.

### Location-Based Services

The AI agent can determine a user's indoor location and provide location-based services (LBS) entirely through image data. The agent learns the positions of different amenities throughout the terminal by recognizing and processing **Zone IDs** posted within the airport environment. This innovative method eliminates the need for conventional indoor positioning infrastructure.

## Network Graph

A network graph generation feature has been added to visualize the relationships between amenities in the airport. It makes use of Gemini for network graph generation from a log file. This feature outputs the generated graph in the `data` folder.

<img src="./docs/network_graph.jpg" width=600>

To run the SvelteKit application for visualizing the network graph:

1.  Navigate to the `viewer` directory: `cd viewer`
2.  Install the dependencies: `npm install`
3.  Start the development server: `npm run dev`

## Development

### Project Structure

```
.
├── airport/              # Godot project
├── blender/              # Blender source files
├── data/                 # Generated data (e.g., network graph)
├── docs/                 # Project documentation
├── images/               # Gemini generated images
├── viewer/               # SvelteKit network graph viewer
└── README.md
```

### Context Engineering

This project is a practical example of context engineering, demonstrating how to build a complex AI agent that interacts with its environment. For more information on the concept of context engineering, please see the [CONTEXT_ENGINEERING.md](docs/CONTEXT_ENGINEERING.md) file.

### Model Context Protocol (MCP)

The underlying specification for the AI's interaction with the airport environment is based on the Model Context Protocol (MCP). For more details, please see the [MCP Specification](./docs/MCP_SPEC.md).

## Future Work

*   Expand the set of tools and resources available to the AI agent.
*   Implement more complex scenarios and interactions in the simulation.
*   Enhance the network graph visualization with more features and data.
*   Integrate with other AI services and APIs.

## License

This project is licensed under the terms of the MIT license.
