import { Process } from "./process.mjs";
import { Library } from "./library.mjs";

export class Runtime {
  hosts = {};
  state = {};

  #pid;
  #logger;

  constructor(pid, logger) {
    this.#pid = pid;
    this.#logger = logger;
  }

  conn(pid, port, hostname) {
    this.hosts[pid] = { pid: pid, port: port, hostname: hostname };
    this.#logger.debug(`Connected to ${pid} at ${hostname}:${port}`);
  }

  init(state) {
    this.state = { ...this.state, ...state };
    this.#logger.debug(`Initialised state to ${JSON.stringify(this.state)}`);
  }

  main() {
    this.call("main");
  }

  call(label) {
    const role = Runtime.roleOf(this.#pid);
    Library.procedures[role][label](this);
  }

  async send(host, message, variable, label) {
    const argv = ["recv", this.state["self"], message, variable, label];
    this.#logger.debug(`Sending ${JSON.stringify(message)} to ${host.pid}...`);
    await Process.fetch(host, argv);
  }

  recv(host, message, variable, label) {
    this.#logger.debug(`Received ${JSON.stringify(message)} from ${host.pid}`);
    this.state[variable] = message;
    this.call(label);
  }

  static roleOf(pid) {
    return pid.match(/([0-9A-Za-z@]+)(?:\[([0-9]+)\])?/)[1];
  }
}
