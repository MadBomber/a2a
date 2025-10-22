# A2A Documentation Diagrams

This directory contains SVG versions of all mermaid diagrams found in the documentation.

## Diagram Inventory

### Converted to SVG (5 diagrams)

1. **protocol-overview.svg** - Main protocol flow (from docs/index.md)
2. **task-lifecycle.svg** - Task state machine (from docs/guides/tasks.md)
3. **getting-started-sequence.svg** - Getting started sequence diagram (from docs/guides/getting-started.md)
4. **message-flow.svg** - Message and parts flow (from docs/guides/messages.md)
5. **architecture-layers.svg** - Layered architecture overview (from docs/architecture/index.md)

### Remaining Mermaid Diagrams to Convert (30+ diagrams)

#### docs/guides/artifacts.md
- Artifact processing flow

#### docs/architecture/design.md
- Separation of concerns graph
- Error hierarchy diagram
- Error categories flow
- Serialization strategy diagram

#### docs/architecture/flow.md
- Core protocol methods graph
- Agent discovery sequence
- Discovery implementation flow
- Task state machine (detailed)
- Task lifecycle sequence
- Synchronous task send sequence
- Synchronous flow with error
- Streaming task sendSubscribe sequence
- SSE event structure
- Multi-turn conversation sequence
- Session context management
- Protocol error flow
- Application error flow
- Error response structure
- Push notification setup and delivery
- Webhook retry flow
- Cancellation sequence
- Cancellation edge cases
- Valid state transition diagram
- State transition rules
- Complete request/response flow
- Model interaction flow
- All protocol methods summary

#### docs/architecture/index.md
- High-level architecture
- Models component architecture
- Protocol component architecture
- Client/server architecture
- Client request flow
- Server request handling flow
- Model composition flow

## Usage in Documentation

To reference these diagrams in markdown files, use:

```markdown
![Diagram Description](assets/diagrams/diagram-name.svg)
```

## Design Guidelines

All SVG diagrams follow these standards:
- **Background**: Transparent
- **Color Scheme**: Dark theme with the following palette:
  - Background boxes: #2d3748
  - Borders: #4a5568
  - Text: #e2e8f0
  - Arrows: #63b3ed
  - Success/completed: #2f855a
  - Errors: #f8d7da
  - Warnings: #744210
- **Fonts**: Arial, sans-serif
- **Line weights**: 2px for main elements, 1px for secondary elements
- **Rounded corners**: 8px for major boxes, 4px for minor boxes

## Converting Remaining Diagrams

To convert the remaining mermaid diagrams to SVG:

1. Extract the mermaid code from the markdown file
2. Use mermaid CLI or online editor (https://mermaid.live)
3. Apply dark theme styling
4. Export as SVG with transparent background
5. Save to this directory with descriptive filename
6. Update the source markdown file to reference the SVG

Alternatively, use the mermaid CLI:

```bash
npm install -g @mermaid-js/mermaid-cli
mmdc -i input.mmd -o output.svg -t dark -b transparent
```
