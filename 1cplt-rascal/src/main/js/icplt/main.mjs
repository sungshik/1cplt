import * as node_fs from 'node:fs';
import * as node_child_process from 'node:child_process';
import { Process } from './process.mjs';
import { Runtime } from './runtime.mjs';

function resolvePidsToHosts(schema, oldData, hosts) {
  let newData = oldData;
  switch (schema.type) {
    case 'array': {
      newData = [];
      for (const v of oldData) {
        newData.push(resolvePidsToHosts(schema.items, v, hosts));
      }
      break;
    }
    case 'object': {
      newData = {};
      for (const x in oldData) {
        newData[x] = resolvePidsToHosts(
          schema.properties[x],
          oldData[x],
          hosts
        );
      }
      break;
    }
    case 'string': {
      newData = schema.default ? hosts[oldData] : oldData;
      break;
    }
  }
  return newData;
}

if (process.argv.length == 2) {
  const json = JSON.parse(node_fs.readFileSync('main.json'));

  // Spawn processes
  const begin = new Date();
  const pids = Object.keys(json.conn);
  const hosts = {};
  for (const pid of pids) {
    const node = node_child_process.spawn('node', ['main.mjs', pid]);

    node.stderr.on('data', async (data) => {
      console.error(data.toString());
    });

    node.stdout.on('data', async (data) => {
      hosts[pid] = JSON.parse(data.toString());

      // If all processes have been spawned, then execute `conn`/`init`/`main`
      if (Object.keys(hosts).length == pids.length) {
        // Execute `conn`
        for (const pi of pids) {
          for (const qj of json.conn[pi]) {
            const host = hosts[qj];
            const argv = ['conn', host.pid, host.port, host.hostname];
            await Process.fetch(hosts[pi], argv);
          }
        }
        // Execute `init`
        for (const rk of pids) {
          const r = Runtime.roleOf(rk);
          const state = resolvePidsToHosts(
            json.schemas[r],
            json.init[rk],
            hosts
          );
          const argv = ['init', state];
          await Process.fetch(hosts[rk], argv);
        }
        // Execute `main`
        for (const rk of pids) {
          const argv = ['main'];
          await Process.fetch(hosts[rk], argv);
        }

        // Await termination...
        Process.awaitTermination(Object.values(hosts), () => {
          const end = new Date();

          // Write execution.md
          const path = 'execution.md';
          node_fs.rmSync(path, { force: true });
          const writeStream = node_fs.createWriteStream(path, { flags: 'a' });
          writeStream.write(`# Execution

  - **Begin:** ${begin.toLocaleString()}
  - **End:**   ${end.toLocaleString()}
`);
          for (const pid of pids) {
            const chunk = `
## \`${pid}\`

\`\`\`log
${node_fs.readFileSync(`${pid}.log`, 'utf8').trimEnd()}
\`\`\`
`;
            writeStream.write(chunk, 'utf8');
          }
          writeStream.end(process.exit);
        });
      }
    });
  }
} else {
  const pid = process.argv[2];
  new Process(pid).open((port, hostname) => {
    const host = { pid: pid, port: port, hostname: hostname };
    console.log(JSON.stringify(host));
  });
}
