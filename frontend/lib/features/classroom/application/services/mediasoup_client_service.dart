import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class MediasoupClientService {
  late Device device;
  IO.Socket? _socket;
  Transport? sendTransport;
  Transport? recvTransport;
  Producer? _videoProducer;
  Producer? _audioProducer;

  void initialize(String classId, IO.Socket socket) {
    _socket = socket;
    device = Device();
  }

  Future<void> loadDevice(dynamic routerRtpCapabilities) async {
    await device.load(routerRtpCapabilities: routerRtpCapabilities);
  }

  Future<void> createSendTransport(IO.Socket socket, String classId) async {
    final completer = Completer<void>();
    socket.emitWithAck(
        'create-transport', {'classId': classId, 'isProducer': true},
        ack: (data) async {
      sendTransport = device.createSendTransport(
        id: data['id'],
        iceParameters: data['iceParameters'],
        iceCandidates: List<IceCandidate>.from(
            data['iceCandidates'].map((c) => IceCandidate.fromMap(c))),
        dtlsParameters: data['dtlsParameters'],
      );

      sendTransport!.on('connect', (dtlsParameters, callback, errback) {
        socket.emitWithAck(
            'connect-transport',
            {
              'classId': classId,
              'transportId': sendTransport!.id,
              'dtlsParameters': dtlsParameters.toMap(),
            },
            ack: (_) => callback());
      });

      sendTransport!.on('produce',
          (kind, rtpParameters, callback, errback) async {
        socket.emitWithAck(
            'produce',
            {
              'classId': classId,
              'transportId': sendTransport!.id,
              'kind': kind,
              'rtpParameters': rtpParameters,
            },
            ack: (producerId) => callback(producerId));
      });

      sendTransport!.on('newproducer', (producer) {
        if (producer.kind == 'video') {
          _videoProducer = producer;
        } else {
          _audioProducer = producer;
        }
      });

      completer.complete();
    });
    return completer.future;
  }

  Future<void> createRecvTransport(IO.Socket socket, String classId) async {
    final completer = Completer<void>();
    socket.emitWithAck(
        'create-transport', {'classId': classId, 'isProducer': false},
        ack: (data) {
      recvTransport = device.createRecvTransport(
        id: data['id'],
        iceParameters: data['iceParameters'],
        iceCandidates: List<IceCandidate>.from(
            data['iceCandidates'].map((c) => IceCandidate.fromMap(c))),
        dtlsParameters: data['dtlsParameters'],
      );

      recvTransport!.on('connect', (dtlsParameters, callback, errback) {
        socket.emitWithAck(
            'connect-transport',
            {
              'classId': classId,
              'transportId': recvTransport!.id,
              'dtlsParameters': dtlsParameters.toMap(),
            },
            ack: (_) => callback());
      });

      completer.complete();
    });
    return completer.future;
  }

  Future<void> consume({
    required IO.Socket socket,
    required Transport transport,
    required String producerId,
    required RtpCapabilities rtpCapabilities,
    required String peerId,
  }) async {
    socket.emitWithAck('consume', {
      'transportId': transport.id,
      'producerId': producerId,
      'rtpCapabilities': rtpCapabilities.toMap(),
    }, ack: (data) async {
      transport.consume(
        id: data['id'],
        producerId: data['producerId'],
        kind: data['kind'],
        rtpParameters: RtpParameters.fromMap(data['rtpParameters']),
        peerId: peerId,
      );
    });
  }

  Future<void> produce({
    required IO.Socket socket,
    required Transport transport,
    required MediaStreamTrack track,
    required MediaStream stream,
    List<RtpEncodingParameters>? encodings,
    String source = 'webcam', // Default to webcam
  }) async {
    transport.produce(
      track: track,
      stream: stream,
      encodings: encodings ?? [],
      source: source,
    );
  }

  Producer? findProducerByTrackKind(String kind) {
    if (kind == 'video') {
      return _videoProducer;
    }
    if (kind == 'audio') {
      return _audioProducer;
    }
    return null;
  }
}
