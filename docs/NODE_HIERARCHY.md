# Node Hierarchy

This document outlines the node hierarchy of the main `Airport.tscn` scene in the Godot project.

## Root Node

The root node of the scene is a `Node3D` named `McpServer`. It serves as the main container for all other nodes in the simulation.

```
- McpServer (Node3D)
```

## Main Nodes

The direct children of the root node are the core components of the simulation:

```
- McpServer (Node3D)
  - DirectionalLight3D
  - WorldEnvironment
  - HTTPRequest
  - Globals (Node)
  - Airport (Node3D)
  - SubViewportContainer
```

*   **`DirectionalLight3D`:** Provides the main source of light for the scene.
*   **`WorldEnvironment`:** Configures the environment of the scene, including the sky, ambient light, and other effects.
*   **`HTTPRequest`:** Used for making HTTP requests to the Gemini API.
*   **`Globals`:** A singleton script that stores global variables and settings.
*   **`Airport`:** A `Node3D` that contains all the physical elements of the airport environment.
*   **`SubViewportContainer`:** A container for the sub-viewport that renders the 3D scene, including the UI and visitor management.

## Airport Node

The `Airport` node contains the physical environment of the airport, including the terminal, doors, flight info displays, and other objects.

```
- Airport (Node3D)
  - Terminal (PackedScene)
  - Levels (PackedScene)
  - Doors (Node3D)
    - 2F-E-5-1 (PackedScene)
    - 2F-E-5-2 (PackedScene)
    - ...
  - FlightInfo (Node3D)
    - Display1 (PackedScene)
    - Display2 (PackedScene)
    - ...
  - Zones (Node3D)
    - 2F-E-5 (Label3D)
    - 2F-E-11 (Label3D)
    - ...
  - Signs (Node3D)
    - Label3D
    - ...
  - Kiosks (Node3D)
    - kiosk (PackedScene)
    - ...
  - Restrooms (Node3D)
    - Restroom-1 (Label3D)
    - ...
  - CheckInKiosks (Node3D)
    - Set1 (Node3D)
      - check_in_1 (PackedScene)
      - ...
    - ...
  - Posters (Node3D)
    - PosterA-2 (Sprite3D)
    - ...
  - SecurityRobot (PackedScene)
```

## Visitor Nodes

The `Visitors` node is a new addition that manages multiple `Visitor` instances. It dynamically adds and removes `Visitor` nodes based on a selection from an `OptionButton` in the UI.

```
- SubViewportContainer
  - SubViewport
    - Visitors (Node)
      - Man (PackedScene)
      - Woman (PackedScene)
```

*   **`Visitors`:** A new node that uses the `visitors.gd` script to manage multiple `Visitor` instances.
*   **`Man` and `Woman`:** Instances of the `Man.tscn` and `Woman.tscn` packed scenes, which represent user-controlled characters. These are dynamically added/removed by `visitors.gd`.
*   **`OptionButton`:** A UI element that allows the user to switch between different `Visitor` instances.

## UI Nodes

The UI nodes are responsible for displaying the chat window and other user interface elements.

```
- SubViewportContainer
  - SubViewport
    - CanvasLayer
      - ChatWindow (TextEdit)
```

*   **`ChatWindow`:** A `TextEdit` node that displays the chat interface.
