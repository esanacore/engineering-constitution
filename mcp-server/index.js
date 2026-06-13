import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CONSTITUTION_ROOT = path.resolve(__dirname, "..");

const server = new Server(
  {
    name: "engineering-constitution",
    version: "1.0.0",
  },
  {
    capabilities: {
      resources: {},
      tools: {},
    },
  }
);

const RESOURCES = [
  {
    uri: "constitution://core/constitution",
    name: "Core Constitution",
    description: "The main Engineering Constitution document",
    path: "CONSTITUTION.md",
  },
  {
    uri: "constitution://core/workflow",
    name: "AI Workflow Guide",
    description: "Guidelines for AI-assisted development workflows",
    path: "AI_WORKFLOW.md",
  },
  {
    uri: "constitution://core/testing",
    name: "Testing Standards",
    description: "Universal testing requirements and expectations",
    path: "TESTING.md",
  },
];

server.setRequestHandler(ListResourcesRequestSchema, async () => {
  return {
    resources: RESOURCES.map((r) => ({
      uri: r.uri,
      name: r.name,
      description: r.description,
      mimeType: "text/markdown",
    })),
  };
});

server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const resource = RESOURCES.find((r) => r.uri === request.params.uri);
  if (!resource) {
    throw new Error(`Resource not found: \${request.params.uri}`);
  }

  const content = await fs.readFile(path.join(CONSTITUTION_ROOT, resource.path), "utf-8");
  return {
    contents: [
      {
        uri: resource.uri,
        mimeType: "text/markdown",
        text: content,
      },
    ],
  };
});

server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "validate_project_structure",
        description: "Checks if a project root has the required constitution files.",
        inputSchema: {
          type: "object",
          properties: {
            projectPath: {
              type: "string",
              description: "The absolute path to the project root.",
            },
          },
          required: ["projectPath"],
        },
      },
    ],
  };
});

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  if (request.params.name === "validate_project_structure") {
    const { projectPath } = request.params.arguments;
    const requiredFiles = ["AGENTS.md", "CHANGELOG.md", "TODO.md", "VERSION"];
    const results = [];

    for (const file of requiredFiles) {
      try {
        await fs.access(path.join(projectPath, file));
        results.push({ file, status: "PRESENT" });
      } catch {
        results.push({ file, status: "MISSING" });
      }
    }

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(results, null, 2),
        },
      ],
    };
  }
  throw new Error(`Tool not found: \${request.params.name}`);
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Engineering Constitution MCP Server running on stdio");
}

main().catch((error) => {
  console.error("Fatal error in main():", error);
  process.exit(1);
});
