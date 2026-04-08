# 2026-04-08-paperclip-mcp-server.md

# Paperclip Tasks MCP Server Implementation Plan

The goal is to implement an MCP (Model Context Protocol) server that allows VS Code (or any MCP-compatible client) to interact with Paperclip's task management system. This will expose the operations defined in `doc/TASKS-mcp.md` as tools for AI agents.

## User Review Required

> [!IMPORTANT]
> **Authentication Method**: The MCP server will require an **Agent API Key** to interact with Paperclip. Users will need to create an agent in the Paperclip UI, generate a key, and configure VS Code with this key.
> 
> **Company Context**: Since Paperclip is multi-tenant/multi-company, the MCP server needs a `COMPANY_ID`. This must be provided in the configuration.
> 
> **Sub-set Implementation**: I will prioritize the `Issues` and `Projects` tools first (the most critical 10-15 operations) to ensure a stable V1, as some entities like "Teams" and "Workflow States" are currently aspirational in the data model.

## Proposed Changes

### Core Integration

#### [NEW] [mcp-server package](file:///c:/Users/Natan/.gemini/antigravity/scratch/Companies/packages/mcp-server)
Create a new package to house the MCP server implementation. This keeps it isolated from the main API but allows it to share logic and dependencies.

- `package.json`: Add `@modelcontextprotocol/sdk`, `@paperclipai/db`, and `@paperclipai/shared`.
- `src/index.ts`: The main entry point using the MCP SDK's `stdio` transport.
- `src/tools/issues.ts`: Implements the `list_issues`, `get_issue`, `create_issue`, etc.
- `src/tools/projects.ts`: Implements the `list_projects`, `get_project` tools.

#### [MODIFY] [Root package.json](file:///c:/Users/Natan/.gemini/antigravity/scratch/Companies/package.json)
Add the new package to the `pnpm` workspaces.

---

### Service Integration

The MCP server will use the existing `IssueService` and `ProjectService` from the `server` package. If direct imports cause circular dependency issues, I will refactor the core logic into a more shared location, but given the current monorepo structure, direct internal imports should be feasible for development.

---

### VS Code Configuration

Once implemented, the user will add the following to their `.vscode/mcp.json` or global configuration:

```json
{
  "mcpServers": {
    "paperclip": {
      "command": "node",
      "args": ["packages/mcp-server/dist/index.js"],
      "env": {
        "PAPERCLIP_URL": "http://localhost:3100",
        "PAPERCLIP_AGENT_KEY": "YOUR_AGENT_API_KEY",
        "COMPANY_ID": "YOUR_COMPANY_UUID"
      }
    }
  }
}
```

## Open Questions

- **Shared Logic**: Should I move the core `IssueService` logic from `server/src/services` to a new `packages/core` or `packages/services` to avoid the `mcp-server` depending on the `server` (Express) package? (I recommend this for long-term health).
- **Tool Coverage**: Are `list_issues`, `create_issue`, `get_issue`, and `update_issue` sufficient for the "V1" of this MCP, or do you specifically need `Milestones` or `Labels` immediately?

## Verification Plan

### Automated Tests
- Create a test script in `packages/mcp-server` that simulates an MCP client connection over stdio.
- Verify that `list_issues` returns the expected data from a local dev database.

### Manual Verification
1. Run Paperclip locally (`pnpm dev`).
2. Generate an agent API key.
3. Configure the MCP server in VS Code.
4. Use the Copilot/Chat view in VS Code to ask "List my open issues in Paperclip" and verify it calls the tool.
