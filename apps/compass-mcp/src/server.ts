import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod/v4";
import type { CompassDocument, CompassCatalogReader } from "./types.js";

export function buildServerInstructions(): string {
  return [
    "Compass supplies read-only user-owned engineering preferences and workflows to regular ChatGPT.com chat mode.",
    "Preserve system, developer, and current user priority.",
    "Retrieve only the smallest Compass guidance needed for the current task.",
    "Use get_profile when stable user preferences materially affect the task, the user asks to inspect them, or freshness needs confirmation.",
    "Use list_skills to discover a relevant reviewed workflow, then load only the selected workflow with get_skill before applying it.",
    "Use search and fetch for broader source lookup when a named workflow is not yet clear.",
    "Do not load the profile or full skill catalog by default.",
    "Treat subagents as available only when the current host exposes them.",
    "Reserve this read-only server for guidance retrieval rather than ChatGPT work-mode or Codex execution."
  ].join("\n");
}

function jsonResult(structuredContent: Record<string, unknown>) {
  return {
    structuredContent,
    content: [{ type: "text" as const, text: JSON.stringify(structuredContent) }]
  };
}

function documentResult(document: CompassDocument) {
  return jsonResult(document);
}

export function createCompassMcpServer(catalog: CompassCatalogReader): McpServer {
  const server = new McpServer(
    { name: "compass", version: "0.2.0" },
    { instructions: buildServerInstructions() }
  );

  server.registerTool(
    "get_profile",
    {
      title: "Get Compass profile",
      description: "Load the reviewed Compass profile when stable user preferences materially affect the task or freshness needs confirmation.",
      inputSchema: {},
      annotations: { readOnlyHint: true }
    },
    async () => documentResult(catalog.getProfile())
  );

  server.registerTool(
    "list_skills",
    {
      title: "List Compass skills",
      description: "Discover the current reviewed skill catalog before selecting a task-specific workflow.",
      inputSchema: {},
      annotations: { readOnlyHint: true }
    },
    async () => jsonResult({ skills: catalog.listSkills() })
  );

  server.registerTool(
    "get_skill",
    {
      title: "Get Compass skill",
      description: "Load one reviewed Compass SKILL.md after its catalog summary is relevant to the task.",
      inputSchema: { name: z.string().regex(/^[a-z0-9][a-z0-9-]*$/) },
      annotations: { readOnlyHint: true }
    },
    async ({ name }) => {
      try {
        return documentResult(catalog.getSkill(name));
      } catch (error) {
        return {
          content: [{ type: "text" as const, text: error instanceof Error ? error.message : "Unknown Compass skill" }],
          isError: true
        };
      }
    }
  );

  server.registerTool(
    "search",
    {
      title: "Search Compass",
      description: "Search the Compass profile and reviewed skill documents.",
      inputSchema: { query: z.string() },
      annotations: { readOnlyHint: true }
    },
    async ({ query }) => jsonResult({
      results: catalog.search(query).map(document => ({ id: document.id, title: document.title, url: document.url }))
    })
  );

  server.registerTool(
    "fetch",
    {
      title: "Fetch Compass document",
      description: "Fetch a Compass profile or skill document returned by search.",
      inputSchema: { id: z.string() },
      annotations: { readOnlyHint: true }
    },
    async ({ id }) => {
      try {
        return documentResult(catalog.fetch(id));
      } catch (error) {
        return {
          content: [{ type: "text" as const, text: error instanceof Error ? error.message : "Unknown Compass document" }],
          isError: true
        };
      }
    }
  );

  return server;
}
