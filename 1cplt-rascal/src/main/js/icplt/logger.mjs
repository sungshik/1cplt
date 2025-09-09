import * as node_fs from "node:fs";

export class Logger {
  #stream;

  constructor(path) {
    node_fs.rmSync(path, { force: true });
    this.#stream = node_fs.createWriteStream(path, { flags: "a" });
  }

  info(message) {
    this.#stream.write(`[INFO] ${message}\n`);
  }

  debug(message) {
    this.#stream.write(`[DEBUG] ${message}\n`);
  }

  trace(message) {
    this.#stream.write(`[TRACE] ${message}\n`);
  }
}
