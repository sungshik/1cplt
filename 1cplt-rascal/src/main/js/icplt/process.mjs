import * as node_http from "node:http";
import { Logger } from "./logger.mjs";
import { Runtime } from "./runtime.mjs";

export class Process {
  #pid;
  #port;
  #hostname;

  #earlyRecvs;
  #logger;
  #runtime;
  #server;

  constructor(pid, port = "0", hostname = "localhost") {
    this.#pid = pid;
    this.#port = port;
    this.#hostname = hostname;

    this.#earlyRecvs = [];
    this.#logger = new Logger(`${this.#pid}.log`);
    this.#runtime = new Runtime(this.#pid, this.#logger);
    this.#server = node_http.createServer((request, response) => {
      const chunks = [];

      request.on("data", (chunk) => {
        chunks.push(chunk);
      });

      request.on("end", () => {
        const body = decodeURIComponent(Buffer.concat(chunks).toString());
        const argv = JSON.parse(body);
        this.#schedule(argv);
        response.statusCode = 200;
        response.setHeader("Content-Type", "text/plain");
        response.end();
      });
    });
  }

  open(callback) {
    this.#server.listen(this.#port, this.#hostname, () => {
      this.#port = this.#server.address().port;
      this.#logger.trace(
        `Opening ${this.#hostname}:${
          this.#port
        } (${new Date().toLocaleString()})...`
      );
      this.#runtime.init({
        self: { pid: this.#pid, port: this.#port, hostname: this.#hostname },
      });
      callback(this.#port, this.#hostname);
    });
  }

  close() {
    this.#server.close();
    this.#server.closeAllConnections();
    this.#logger.trace(`Closed ${this.#hostname}:${this.#port}`);
  }

  #schedule(argv) {
    if (argv[0] === "recv" && this.#earlyRecvs) {
      this.#earlyRecvs.push(argv);
    } else if (argv[0] === "main") {
      this.#scheduleNow(argv);
      this.#earlyRecvs.forEach((argv) => this.#scheduleNow(argv));
      this.#earlyRecvs = undefined;
    } else {
      this.#scheduleNow(argv);
    }
  }

  #scheduleNow(argv) {
    const f = this.#runtime[argv[0]];
    const thisArg = this.#runtime;
    const argsArray = argv.slice(1);
    setImmediate(() => f.apply(thisArg, argsArray));
    this.#logger.trace(`Scheduled ${JSON.stringify(argv)}`);
  }

  static async fetch(host, argv) {
    const resource = `http://${host.hostname}:${host.port}`;
    const method = "POST";
    const body = encodeURIComponent(JSON.stringify(argv));
    await fetch(resource, { method: method, body: body });
  }
}
