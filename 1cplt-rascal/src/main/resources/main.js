/* -------------------------------------------------------------------------- */
/*                                Dependencies                                */
/* -------------------------------------------------------------------------- */

const url           = require('url');
const child_process = require('node:child_process');
const fs            = require('node:fs');
const http          = require('node:http');
const os            = require('node:os');
const readline      = require('node:readline');

const Ajv = require("ajv")
const ajv = new Ajv()

/* -------------------------------------------------------------------------- */
/*                                  Runtime                                   */
/* -------------------------------------------------------------------------- */

let recvsBeforeMain = [];
let state = {};

class API {
  static init(role, data) {
    const json = JSON.parse(fs.readFileSync(jsonPath));
    const schema = json.schemas[role];
    this.#validate(schema, data);
    state = this.#resolve(schema, data);
    state.self = Address.book.self;
  }

  static call(name) {
    procedures[Address.book.self.getRole()][name]();
    if (recvsBeforeMain && name === 'main') {
      for (const recv of recvsBeforeMain) {
        recv();
      }
      recvsBeforeMain = null;
    }
  }

  static async send(_address, message, label) {
    const address = new Address();
    Object.assign(address, _address);

    const argv = `recv [${JSON.stringify(message)}, ${JSON.stringify(label)}]`;
    await fetch(address.getUrl(), { method: 'POST', body: `?argv=${encodeURIComponent(argv)}` });
  }

  static recv(message, label) {
    const recv = () => continuations[label](message);
    if (recvsBeforeMain) {
      recvsBeforeMain.push(recv);
    } else {
      recv();
    }
  }

  static #validate(schema, data) {
    if (!ajv.validate(schema, data)) {
      const error = ajv.errors[0];
      switch (error.keyword) {
        case 'type': {
          const x = error.instancePath.substring(1);
          const t = error.params.type;
          throw new Error(`Expected data type of \`${x}\`: \`${t}\`. Actual: \`${(typeof data[x]) ?? 'failed to infer'}\`.`);
        }
        case 'required': {
          const expected = `\`${schema.required.join('\`, \`')}\``;
          const actual = `\`${Object.getOwnPropertyNames(data).join('\`, \`')}\``;
          throw new Error(`Expected data variables: ${expected}. Actual: ${actual !== '``' ? actual : 'none'}.`);
        }
        default:
          throw new Error(`Unexpected error. Details:\n\n${error}`);
      }
    }
  }

  static #resolve(schema, oldData) {
    let newData = oldData;
    switch (schema.type) {
      case 'object': {
        newData = {};
        for (const x in oldData) {
          newData[x] = this.#resolve(schema.properties[x], oldData[x]);
        }
        break;
      }
      case 'array': {
        newData = [];
        for (const v of oldData) {
          newData.push(this.#resolve(schema.items, v));
        }
        break;
      }
      case 'string': {
        newData = schema.default ? Address.of(oldData) : oldData;
        break;
      }
    }
    return newData;
  }
}

class Address {
  constructor(pid, hostname, port) {
    this.pid = pid;
    this.hostname = hostname ?? 'localhost';
    this.port = port ?? 0;
  }

  getRole() {
    return this.pid.match(/([0-9A-Za-z]+)(?:\[([0-9]+)\])?/)[1];
  }

  getUrl() {
    return `http://${this.hostname}:${this.port}`;
  }

  toString() {
    return `${this.pid}@${this.hostname}:${this.port}`;
  }

  static book = {}

  static of(pid) {
    return Address.book[pid] ?? (() => { throw new Error(`Unexpected process identifier: ${pid}`); })();
  }

  static fromString(s) {
    try {
      const [_, pid, hostname, port] = s.match(
        /^([0-9A-Za-z\[\]]+)(?:@([0-9A-Za-z\.]+)(?:\:([0-9]+))?)?$/);
      return new Address(pid, hostname, port);
    } catch (e) {
      return null;
    }
  }
}

/* -------------------------------------------------------------------------- */
/*                                    Main                                    */
/* -------------------------------------------------------------------------- */

class Argv {

  static getPid() {
    const last = process.argv[this.#length() - 1];
    if (Address.fromString(last)) {
      return last;
    } else {
      return null;
    }
  }

  static interactive() {
    return this.#options().includes('--interactive') || this.#options().includes('-i');
  }

  static verbose() {
    return this.#options().includes('--verbose') || this.#options().includes('-v');
  }

  static #length() {
    return process.argv.length;
  }

  static #options() {
    const start = 2;
    const end = this.#length() - (this.getPid() ? 1 : 0);
    return process.argv.slice(start, end);
  }
}

class Terminal {

  static #interface = null;
  static #historyFile = `${os.homedir}/.1cplt_js_history`;
  static #reading = false;

  static open() {
    this.#interface = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      terminal: true,
      history: fs.existsSync(this.#historyFile) ? JSON.parse(fs.readFileSync(this.#historyFile)).history : []
    });
    this.#interface.on('history', history => {
      fs.writeFileSync(this.#historyFile, `${JSON.stringify({history: history}, 2)}\n`);
    });
  }

  static close() {
    if (this.#reading) {
      this.#reading = false;
      this.write('');
    }
    this.#interface.input.unref();
  }

  static info(message) {
    this.write(`[INFO] ${message}`);
  }

  static error(message) {
    this.write(`[ERROR] ${message}`);
  }

  static write(message) {
    const prefix = this.#reading ? '\n\n' : '\n';
    const suffix = this.#reading ? `\n\n${this.#prompt()}` : '';
    process.stdout.write(`${prefix}${message}${suffix}\n`);
  }

  static read() {
    this.#reading = true;
    this.#interface.question(`\n${this.#prompt()}`, answer => {
      this.#reading = false;
      const argv = answer.split(' ');
      dispatch(argv);
      this.read();
    });
  }

  static #prompt() {
    return `${Argv.getPid() ?? ''}> `;
  }
}

class Server {
  static create() {
    const server = http.createServer((request, response) => {
      let chunks = [];
      request.on('error', error => {
        dispatch('error', error)
      });
      request.on('data', data => {
        chunks.push(data);
      });
      request.on('end', () => {
        const body = Buffer.concat(chunks).toString();
        const argv = decodeURIComponent(url.parse(body, true).query.argv).split(' ');
        dispatch(argv);
        response.statusCode = 200;
        response.setHeader('Content-Type', 'text/plain');
        response.end();
      });
    });

    server.listen(Address.book.self.port, Address.book.self.hostname, () => {
      Address.book.self.port = server.address().port;
      if (!Argv.interactive()) {
        console.log(Address.book.self.toString());
      }
      Terminal.info(`Listening at ${Address.book.self.getUrl()}`)
      if (Argv.interactive()) {
        Terminal.read();
      }
    });
  }
}

async function dispatch(argv) {
  try {
    switch (argv[0]) {

      case 'conn': {
        const address = Address.fromString(argv[1]);
        Address.book[address.pid] = address;
        Terminal.info(`Connected to ${argv[1]}`);
        break;
      }

      case 'init': {
        const data = JSON.parse(argv.slice(1).join(' '));
        API.init(Address.book.self.getRole(), data);
        Terminal.info('Initialized')
        break;
      }

      case 'call': {
        const name = argv[1];
        Terminal.info(`Calling \`${name}\`...`)
        setTimeout(() => API.call(name));
        break;
      }

      case 'send': {
        const [_address, message, label] = JSON.parse(argv.slice(1).join(' '));
        const address = new Address();
        Object.assign(address, _address);
        Terminal.info(`Sending \`${JSON.stringify(message)}\` (${label}) to ${address.toString()}...`)
        setTimeout(() => API.send(address, message, label));
        break;
      }

      case 'recv': {
        const [message, label] = JSON.parse(argv.slice(1).join(' '));
        Terminal.info(`Receiving \`${JSON.stringify(message)}\` (${label})...`)
        setTimeout(() => API.recv(message, label));
        break;
      }

      case 'exit': {
        Terminal.info('Exited\n')
        process.exit();
      }

      case '': {
        Terminal.info(JSON.stringify(state, null, 2));
        break;
      }

      default: {
        throw new Error(`Unexpected command: ${argv[0]}`);
      }
    }
  } catch (e) {
    const stack = Argv.verbose() ? `\n${e.stack.substring(e.stack.indexOf('\n'))}` : '';
    Terminal.error(`${e.message}${stack}`);
  }
};

function main() {
  Terminal.open();

  if (Argv.getPid()) {
    Address.book.self = Address.fromString(Argv.getPid());
    Server.create();
    state['self'] = Address.book.self;
  }

  else {
    const json = JSON.parse(fs.readFileSync(jsonPath));
    const nodes = new Map();
    const addresses = new Map();

    // Spawn processes
    for (const pid in json.conn) {
      const node = child_process.spawn('node', [jsPath, '-v', `${pid}@localhost:0`]);

      node.stderr.on('data', async data => {
        console.error(data.toString());
      });

      node.stdout.on('data', async data => {
        const lines = data.toString().split('\n');
        for (const line of lines) {
          if (line !== '') {
            if (!addresses.has(pid)) {
              const address = Address.fromString(line);
              addresses.set(pid, address);
              if (addresses.size === nodes.size) {

                // Connect and initialize processes
                for (const pi in json.conn) {
                  for (const qj of json.conn[pi]) {
                    const argv = `conn ${addresses.get(qj)}`;
                    await fetch(addresses.get(pi).getUrl(), { method: "POST", body: `?argv=${encodeURIComponent(argv)}` });
                  }

                  const argv = `init ${JSON.stringify(json.init[pi])}`;
                  await fetch(addresses.get(pi).getUrl(), { method: "POST", body: `?argv=${encodeURIComponent(argv)}` });
                }

                // Start processes
                for (const pi in json.conn) {
                  const argv = `call main`;
                  await fetch(addresses.get(pi).getUrl(), { method: "POST", body: `?argv=${encodeURIComponent(argv)}` });
                }
              }
            }

            else {
              const name = pid.substring(0, pid.length - (pid.endsWith('[0]') ? 3 : 0));
              if (line.startsWith('[INFO]')) {
                console.log(`[INFO] ${name}: ${line.substring(7)}`);
              } else if (line.startsWith('[ERROR]')) {
                console.log(`[ERROR] ${name}: ${line.substring(8)}`);
              } else {
                console.log(`[TRACE] ${name}: ${line}`);
              }
            }
          }
        }
      });

      nodes.set(pid, node);
    }
  }
}

main();
