import * as node_fs from 'node:fs';
import { Process } from './process.mjs';
import { Library } from './library.mjs';

export class Runtime {
  hosts = {};
  state = {};

  #pid;
  #logger;

  #delay;

  #mainBeginCount;
  #mainEndCount;
  #sendBeginCount;
  #recvEndCount;

  constructor(pid, logger) {
    this.#pid = pid;
    this.#logger = logger;
    this.#delay = 1;

    this.#mainBeginCount = 0;
    this.#mainEndCount = 0;
    this.#sendBeginCount = 0;
    this.#recvEndCount = 0;
  }

  get statistics() {
    return {
      mainBeginCount: this.#mainBeginCount,
      mainEndCount: this.#mainEndCount,
      sendBeginCount: this.#sendBeginCount,
      recvEndCount: this.#recvEndCount,
    };
  }

  conn(pid, port, hostname) {
    this.hosts[pid] = { pid: pid, port: port, hostname: hostname };
    this.#logger.debug(`Connected to ${pid} at ${hostname}:${port}`);
  }

  init(state) {
    this.state = { ...this.state, ...state };
    this.#logger.debug(`Initialised state: ${JSON.stringify(this.state)}`);
  }

  main() {
    this.#mainBeginCount++;
    this.call('main');
    this.#mainEndCount++;
  }

  call(label) {
    const role = Runtime.roleOf(this.#pid);
    Library.procedures[role][label](this);
  }

  send(host, message, variable, label) {
    this.#sendBeginCount++;
    const argv = ['recv', this.state['self'], message, variable, label];
    this.#logger.debug(`Sending ${JSON.stringify(message)} to ${host.pid}...`);
    setTimeout(async () => await Process.fetch(host, argv), this.#delay);
    this.#delay = 1;
  }

  recv(host, message, variable, label) {
    this.#logger.debug(`Received ${JSON.stringify(message)} from ${host.pid}`);
    this.state[variable] = message;
    this.call(label);
    this.#recvEndCount++;
  }

  load() {
    try {
      const state = JSON.parse(node_fs.readFileSync(`${this.#pid}.json`));
      this.state = { ...this.state, ...state };
      this.#logger.debug(`Loaded state: ${JSON.stringify(this.state)}`);
    } catch (e) {
      this.#logger.error(`Failed to load state`);
    }
  }

  save() {
    try {
      node_fs.writeFileSync(`${this.#pid}.json`, JSON.stringify(this.state));
      this.#logger.debug(`Saved state: ${JSON.stringify(this.state)}`);
    } catch (e) {
      this.#logger.error(`Failed to save state`);
    }
  }

  echo(value) {
    this.#logger.info(JSON.stringify(value));
  }

  ping(delay) {
    this.#delay = delay;
  }

  static roleOf(pid) {
    return pid.match(/([0-9A-Za-z@]+)(?:\[([0-9]+)\])?/)[1];
  }
}
