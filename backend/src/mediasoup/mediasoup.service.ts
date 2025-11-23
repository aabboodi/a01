import { Injectable, OnModuleInit } from '@nestjs/common';
import * as mediasoup from 'mediasoup';

@Injectable()
export class MediasoupService implements OnModuleInit {
  private worker: mediasoup.types.Worker;

  async onModuleInit() {
    this.worker = await mediasoup.createWorker({
      logLevel: 'warn',
    });
    console.log('Mediasoup worker created');
  }

  getWorker(): mediasoup.types.Worker {
    return this.worker;
  }
}
