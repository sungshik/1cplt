import * as node_fs from "node:fs";
import { Process } from "./process.mjs";
import { Runtime } from "./runtime.mjs";

const date = new Date();
const json = JSON.parse(node_fs.readFileSync("main.json"));
const pids = Object.keys(json.conn);

function main() {
  const hosts = {};

  const resolvePidsToHosts = (schema, oldData) => {
    let newData = oldData;
    switch (schema.type) {
      case "array": {
        newData = [];
        for (const v of oldData) {
          newData.push(resolvePidsToHosts(schema.items, v));
        }
        break;
      }
      case "object": {
        newData = {};
        for (const x in oldData) {
          newData[x] = resolvePidsToHosts(schema.properties[x], oldData[x]);
        }
        break;
      }
      case "string": {
        newData = schema.default ? hosts[oldData] : oldData;
        break;
      }
    }
    return newData;
  };

  // Spawn processes
  for (const pid of pids) {
    const p = new Process(pid);
    p.open(async (port, hostname) => {
      hosts[pid] = { pid: pid, port: port, hostname: hostname };

      // If all processes have been spawned, then execute `conn`/`init`/`main`
      if (Object.keys(hosts).length == pids.length) {
        // Execute `conn`
        for (const pi of pids) {
          for (const qj of json.conn[pi]) {
            const host = hosts[qj];
            const argv = ["conn", host.pid, host.port, host.hostname];
            Process.fetch(hosts[pi], argv);
          }
        }
        // Execute `init`
        for (const rk of pids) {
          const r = Runtime.roleOf(rk);
          const state = resolvePidsToHosts(json.schemas[r], json.init[rk]);
          const argv = ["init", state];
          Process.fetch(hosts[rk], argv);
        }
        // Execute `main`
        for (const rk of pids) {
          const argv = ["main"];
          Process.fetch(hosts[rk], argv);
        }
      }
    });
  }
}

function exit() {
  const path = "execution.md";
  node_fs.rmSync(path, { force: true });
  const writeStream = node_fs.createWriteStream(path, { flags: "a" });
  writeStream.write(`# Execution (${date.toLocaleString()})\n`);
  for (const pid of pids) {
    const chunk = `
## \`${pid}\`

\`\`\`log
${node_fs.readFileSync(`${pid}.log`, "utf8").trimEnd()}
\`\`\`
`;
    writeStream.write(chunk, "utf8");
  }
  writeStream.end(process.exit);
}

main();
setTimeout(exit, 1000);
