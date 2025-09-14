import * as node_http from 'node:http';
import { Logger } from './logger.mjs';
import { Runtime } from './runtime.mjs';

export class Process {
  #pid;
  #port;
  #hostname;

  #logger;
  #runtime;
  #earlyRecvs;
  #server;

  constructor(pid, port = '0', hostname = 'localhost') {
    this.#pid = pid;
    this.#port = port;
    this.#hostname = hostname;

    this.#logger = new Logger(`${this.#pid}.log`);
    this.#runtime = new Runtime(this.#pid, this.#logger);
    this.#earlyRecvs = [];
    this.#server = node_http.createServer((request, response) => {
      const chunks = [];

      request.on('data', (chunk) => {
        chunks.push(chunk);
      });

      request.on('end', () => {
        const body = decodeURIComponent(Buffer.concat(chunks).toString());
        const argv = JSON.parse(body);

        let chunk = '';
        switch (argv[0]) {
          case 'stat':
            chunk = JSON.stringify(this.#runtime.statistics);
            break;
          case 'main':
            this.#schedule(argv);
            this.#earlyRecvs.forEach((argv) => this.#schedule(argv));
            this.#earlyRecvs = undefined;
            break;
          case 'recv':
            if (this.#earlyRecvs) {
              this.#earlyRecvs.push(argv);
            } else {
              this.#schedule(argv);
            }
            break;
          case 'kill':
            this.close();
            break;
          default:
            this.#schedule(argv);
        }

        response.statusCode = 200;
        response.setHeader('Content-Type', 'text/plain');
        response.write(chunk, 'utf8');
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
    this.#logger.trace(`Closed ${this.#hostname}:${this.#port}`);
  }

  #schedule(argv) {
    const f = this.#runtime[argv[0]];
    const thisArg = this.#runtime;
    const argsArray = argv.slice(1);
    setImmediate(() => f.apply(thisArg, argsArray));
    this.#logger.trace(`Scheduled ${JSON.stringify(argv)}`);
  }

  static fetch(host, argv) {
    const resource = `http://${host.hostname}:${host.port}`;
    const method = 'POST';
    const body = encodeURIComponent(JSON.stringify(argv));
    return fetch(resource, { method: method, body: body });
  }

  static async awaitTermination(hosts, callback) {
    let mainBeginCount = 0;
    let mainEndCount = 0;
    let sendBeginCount = 0;
    let recvEndCount = 0;

    for (const host of hosts) {
      const response = await this.fetch(host, ['stat']);
      const stats = await response.json();
      mainBeginCount += stats.mainBeginCount;
      mainEndCount += stats.mainEndCount;
      sendBeginCount += stats.sendBeginCount;
      recvEndCount += stats.recvEndCount;
    }

    if (
      mainBeginCount > 0 &&
      mainBeginCount == mainEndCount &&
      sendBeginCount == recvEndCount
    ) {
      for (const host of hosts) {
        await this.fetch(host, ['kill']);
      }
      callback();
    } else {
      setTimeout(() => this.awaitTermination(hosts, callback), 1000);
    }
  }
}
