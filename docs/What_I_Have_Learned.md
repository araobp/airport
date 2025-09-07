# The Problems I Have Learned on MCP Through This Project

## Limitations for Server-to-Server Interoperability

*   **Centralized orchestration required:** To achieve a workflow that involves multiple servers, the AI client or a host must orchestrate the data flow. Data must be retrieved from one server and explicitly passed as input to another.
*   **Incompatible internal representations:** Different servers might use incompatible internal data formats, which an AI client must manage and translate.
*   **Data abstraction barrier:** The "tool" abstraction limits direct server-to-server communication, requiring the AI to act as a go-between.

## Workarounds for Data Exchange

Despite the limitations, developers use several strategies to enable data exchange between servers:

*   **Standardizing interface data:** Developers can agree to use a common JSON Schema for specific data types in their tool inputs and outputs.
*   **Using resource endpoints:** One server can expose data via a URL resource, and another server can consume it, enabling direct data transfer via network protocols like HTTP.
*   **Implementing a "bus" pattern:** A specialized MCP server can act as a broker, centralizing data routing and transformation between other servers.

## Implementation Examples in This Project

### Amenity Locations

In this project, the AI agent learns the locations of amenities through visual-based interaction. When a user asks about an amenity, the AI captures an image, identifies the amenity and the zone ID, and then logs this information. This demonstrates how an AI client can orchestrate a workflow between a vision server (for image analysis) and a data logging server (for storing the location). The data is passed from the vision server to the logging server through the AI client.

### User Feedback

Similarly, user feedback is captured and analyzed. When a user provides feedback, the AI client sends the feedback to a sentiment analysis server. The result of the analysis is then used to improve the AI's behavior. This is another example of centralized orchestration, where the AI client acts as the central hub for data flow between different servers.

### Client-Server Cooperation through Common Data Format

In this project, the client and server cooperate through a common data format based on JSON. For example, when the AI agent identifies an amenity, it sends a JSON object to the logging server with the following structure:

```json
{
  "timestamp": "2025-09-07T12:00:00Z",
  "visitor_id": "Visitor1",
  "zone_id": "2F-C-11",
  "amenity": "Vending Machine"
}
```

This structured data format, based on an implicit JSON schema, allows the client and server to communicate effectively, even though they might have different internal implementations. This is an example of "Standardizing interface data" as a workaround for the limitations of MCP.