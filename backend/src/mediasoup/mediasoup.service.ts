import { Injectable, OnModuleInit } from '@nestjs/common';
import * as mediasoup from 'mediasoup';
import { Worker } from 'mediasoup/node/lib/Worker';

@Injectable()
export class MediasoupService implements OnModuleInit {
  private worker: Worker;

  async onModuleInit() {
    this.worker = await mediasoup.createWorker({
      logLevel: 'warn',
    });
    console.log('Mediasoup worker created');
  }

  getWorker(): Worker {
    return this.worker;
  }
}
