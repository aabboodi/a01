import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MediasoupClientService {
  late Device _device;
  late IO.Socket _socket;
  SendTransport? sendTransport;
  RecvTransport? recvTransport;
  Producer? _videoProducer;
  Producer? _audioProducer;

  Future<void> initialize(String classId, IO.Socket socket) async {
    _socket = socket;
    _device = Device();

    // Get Router RTP Capabilities from the server
    _socket.emit('get-router-rtp-capabilities', {'classId': classId});

    _socket.on('router-rtp-capabilities', (data) async {
      final routerRtpCapabilities = RtpCapabilities.fromMap(data);
      await _device.load(routerRtpCapabilities: routerRtpCapabilities);
    });
  }

  Device get device => _device;

  Future<void> createSendTransport(IO.Socket socket, String classId) async {
    final completer = Completer();
    _socket.emit('create-transport', {'classId': classId, 'isProducer': true});

    _socket.on('transport-created', (data) async {
      sendTransport = device.createSendTransport(
        id: data['id'],
        iceParameters: IceParameters.fromMap(data['iceParameters']),
        iceCandidates: (data['iceCandidates'] as List<dynamic>).map((e) => IceCandidate.fromMap(e)).toList(),
        dtlsParameters: DtlsParameters.fromMap(data['dtlsParameters']),
      );

      sendTransport!.on('connect', (options) {
        _socket.emit('connect-transport', {
          'classId': classId,
          'transportId': sendTransport!.id,
          'dtlsParameters': options.dtlsParameters.toMap(),
        });
      });

      sendTransport!.on('produce', (options) async {
        final result = await socket.call('produce', {
          'classId': classId,
          'transportId': sendTransport!.id,
          'kind': options.kind,
          'rtpParameters': options.rtpParameters.toMap(),
        });
        return result['id'];
      });

      completer.complete();
});

recvTransport!.on('connectionstatechange', (state) {
if (state == 'failed' || state == 'disconnected') {
// Pause video consumer, keep audio consumer running
} else if (state == 'connected') {
// Resume video consumer
}
});

completer.complete();
    });
    return completer.future;
  }

  Future<void> createRecvTransport(IO.Socket socket, String classId) async {
    final completer = Completer();
    _socket.emit('create-transport', {'classId': classId, 'isProducer': false});

    _socket.on('transport-created', (data) {
      recvTransport = device.createRecvTransport(
        id: data['id'],
        iceParameters: IceParameters.fromMap(data['iceParameters']),
        iceCandidates: (data['iceCandidates'] as List<dynamic>).map((e) => IceCandidate.fromMap(e)).toList(),
        dtlsParameters: DtlsParameters.fromMap(data['dtlsParameters']),
      );

      recvTransport!.on('connect', (options) {
        _socket.emit('connect-transport', {
          'classId': classId,
          'transportId': recvTransport!.id,
          'dtlsParameters': options.dtlsParameters.toMap(),
        });
      });

      completer.complete();
    });
    return completer.future;
  }

  Future<Consumer> consume({
    required IO.Socket socket,
    required RecvTransport transport,
    required String producerId,
    required RtpCapabilities rtpCapabilities,
  }) async {
    final result = await socket.call('consume', {
      'transportId': transport.id,
      'producerId': producerId,
      'rtpCapabilities': rtpCapabilities.toMap(),
    });

    final consumer = await transport.consume(
      id: result['id'],
      producerId: result['producerId'],
      kind: result['kind'],
      rtpParameters: RtpParameters.fromMap(result['rtpParameters']),
    );

    return consumer;
  }

  Future<Producer> produce({
    required IO.Socket socket,
    required SendTransport transport,
    required MediaStreamTrack track,
    List<RtpEncodingParameters>? encodings,
  }) async {
    final producer = await transport.produce(
      track: track,
      encodings: encodings,
    );

    return producer;
  }
}
