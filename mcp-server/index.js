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
  {
    uri: "constitution://core/code-style",
    name: "Code Style Standards",
    description: "Principle requiring official, canonical style guides for code style, docstrings, comments, and diagrams",
    path: "CODE_STYLE.md",
  },
  {
    uri: "constitution://core/style-guide-registry",
    name: "Style Guide Registry",
    description: "Registry of official style guide URLs and docstring conventions by language/platform",
    path: "sources/STYLE_GUIDES.md",
  },
];

const SOURCE_SUMMARY_URI_PREFIX = "constitution://source-summary/";
const SUMMARIES_ROOT = path.join(CONSTITUTION_ROOT, "sources", "summaries");

// Recursively list every .md file under SUMMARIES_ROOT, returned as
// forward-slash relative paths. New summaries appear without redeploying
// because this walks the filesystem at request time. See KNOWLEDGE_SOURCES.md.
async function listSourceSummaries(dir = SUMMARIES_ROOT, prefix = "") {
  let entries;
  try {
    entries = await fs.readdir(dir, { withFileTypes: true });
  } catch {
    return [];
  }

  const results = [];
  for (const entry of entries) {
    const relPath = prefix ? `${prefix}/${entry.name}` : entry.name;
    if (entry.isDirectory()) {
      results.push(...(await listSourceSummaries(path.join(dir, entry.name), relPath)));
    } else if (entry.isFile() && entry.name.toLowerCase().endsWith(".md")) {
      results.push(relPath);
    }
  }
  return results;
}

server.setRequestHandler(ListResourcesRequestSchema, async () => {
  const summaryPaths = await listSourceSummaries();
  const summaryResources = summaryPaths.map((relPath) => ({
    uri: `${SOURCE_SUMMARY_URI_PREFIX}${relPath}`,
    name: `Source Summary: ${relPath}`,
    description: `Distilled summary of a knowledge source (${relPath})`,
    mimeType: "text/markdown",
  }));

  return {
    resources: [
      ...RESOURCES.map((r) => ({
        uri: r.uri,
        name: r.name,
        description: r.description,
        mimeType: "text/markdown",
      })),
      ...summaryResources,
    ],
  };
});

server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const { uri } = request.params;

  if (uri.startsWith(SOURCE_SUMMARY_URI_PREFIX)) {
    const relPath = uri.slice(SOURCE_SUMMARY_URI_PREFIX.length);
    const content = await fs.readFile(path.join(SUMMARIES_ROOT, relPath), "utf-8");
    return {
      contents: [
        {
          uri,
          mimeType: "text/markdown",
          text: content,
        },
      ],
    };
  }

  const resource = RESOURCES.find((r) => r.uri === uri);
  if (!resource) {
    throw new Error(`Resource not found: \${uri}`);
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
