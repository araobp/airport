# What I Have Learned About MCP

## What MCP Standardizes

*   **External communication:** MCP standardizes the communication protocol between an AI client and external MCP servers, typically using JSON-RPC 2.0.
*   **Tool discovery:** Servers use the protocol to advertise their available "tools," "resources," and "prompts" to AI clients.
*   **Configuration:** The protocol defines how to configure servers using a common `mcp.json` file, specifying the command, arguments, and environment variables.

## What MCP Does Not Standardize

*   **Internal data structures:** MCP does not dictate the internal implementation of a server, including its data structures, databases, or programming language.
*   **Server-to-server data exchange:** There is no standardized mechanism for different MCP servers to directly exchange data with each other.

## Benefits of the MCP Design

*   **Flexibility and adaptability:** Server developers can integrate with legacy systems or use specialized internal databases without being constrained by the protocol.
*   **Encourages adoption:** Developers can easily wrap existing tools with a lightweight MCP server, rather than rewriting internal logic.
*   **Decoupling:** AI hosts and MCP servers can evolve independently, as long as they adhere to the standard interface.

## Limitations for Server-to-Server Interoperability

*   **Centralized orchestration required:** To achieve a workflow that involves multiple servers, the AI client or a host must orchestrate the data flow. Data must be retrieved from one server and explicitly passed as input to another.
*   **Incompatible internal representations:** Different servers might use incompatible internal data formats, which an AI client must manage and translate.
*   **Data abstraction barrier:** The "tool" abstraction limits direct server-to-server communication, requiring the AI to act as a go-between.

## Workarounds for Data Exchange

Despite the limitations, developers use several strategies to enable data exchange between servers:

*   **Standardizing interface data:** Developers can agree to use a common JSON Schema for specific data types in their tool inputs and outputs.
*   **Using resource endpoints:** One server can expose data via a URL resource, and another server can consume it, enabling direct data transfer via network protocols like HTTP.
*   **Implementing a "bus" pattern:** A specialized MCP server can act as a broker, centralizing data routing and transformation between other servers.