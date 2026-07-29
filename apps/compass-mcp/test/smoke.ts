import assert from "node:assert/strict";
import { once } from "node:events";
import { request } from "node:http";
import { fileURLToPath } from "node:url";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import { startServer } from "../src/index.js";

process.env.COMPASS_ROOT = process.env.COMPASS_ROOT ?? fileURLToPath(new URL("../../..", import.meta.url));
process.env.HOST = "127.0.0.1";
process.env.PORT = "33117";
process.env.ALLOWED_HOSTS = "127.0.0.1,compass.example.test";

function getHealthStatus(host: string): Promise<number | undefined> {
  return new Promise((resolve, reject) => {
    const req = request({
      host: "127.0.0.1",
      port: 33117,
      path: "/healthz",
      method: "GET",
      headers: { host }
    }, res => {
      res.resume();
      res.on("end", () => resolve(res.statusCode));
    });
    req.on("error", reject);
    req.end();
  });
}

const httpServer = startServer();
if (!httpServer.listening) await once(httpServer, "listening");

const client = new Client({ name: "compass-smoke", version: "0.1.0" });
const transport = new StreamableHTTPClientTransport(new URL("http://127.0.0.1:33117/mcp"));

try {
  assert.equal(await getHealthStatus("compass.example.test"), 200);

  await client.connect(transport);
  const instructions = client.getInstructions() ?? "";
  assert.match(instructions, /# User Preferences/);
  assert.match(instructions, /No reviewed Compass skills are active in this bundle/);
  assert.doesNotMatch(instructions, /run-a-micro-experiment/);

  const tools = await client.listTools();
  assert.deepEqual(
    tools.tools.map(tool => tool.name).sort(),
    ["fetch", "get_profile", "get_skill", "list_skills", "search"]
  );
  assert.match(tools.tools.find(tool => tool.name === "list_skills")?.description ?? "", /current reviewed skill catalog/);

  const profile = await client.callTool({ name: "get_profile", arguments: {} });
  assert.equal(profile.isError, undefined);
  const profileText = JSON.stringify(profile);
  assert.match(profileText, /Prefer a pull request as the unit for repository changes/);
  assert.doesNotMatch(profileText, /GPT-5\.6 Sol|GLM-5\.2/);

  const skills = await client.callTool({ name: "list_skills", arguments: {} });
  assert.equal(skills.isError, undefined);
  assert.match(JSON.stringify(skills), /"skills":\[\]/);

  const skill = await client.callTool({ name: "get_skill", arguments: { name: "run-a-micro-experiment" } });
  assert.equal(skill.isError, true);
  assert.match(JSON.stringify(skill), /Unknown Compass skill/);

  const search = await client.callTool({ name: "search", arguments: { query: "pull request" } });
  assert.match(JSON.stringify(search), /"id":"profile"/);
  assert.doesNotMatch(JSON.stringify(search), /skill:/);

  console.log("compass mcp smoke: ok");
} finally {
  await client.close();
  httpServer.close();
  await once(httpServer, "close");
}
