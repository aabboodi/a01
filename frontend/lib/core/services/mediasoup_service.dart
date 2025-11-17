import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MediasoupService {
  late Device _device;
  late IO.Socket _socket;

  RtpCapabilities get rtpCapabilities => _device.rtpCapabilities;

  Future<void> connect(String classId, String token) async {
    _socket = IO.io('http://10.0.2.2:3000/mediasoup', <String, dynamic>{
      'transports': ['websocket'],
      'auth': {'token': token},
    });

    _socket.connect();

    await Future.delayed(const Duration(seconds: 1)); // Allow time for connection

    final routerRtpCapabilities = await _socket.call('getRouterRtpCapabilities', {'classId': classId});

    _device = Device();
    await _device.load(routerRtpCapabilities: routerRtpCapabilities);
  }

  Future<SendTransport> createSendTransport(String classId) async {
    final params = await _socket.call('createWebRtcTransport', {
      'classId': classId,
      'producing': true,
      'consuming': false,
    });

    final transport = _device.createSendTransport(
      id: params['id'],
      iceParameters: params['iceParameters'],
      iceCandidates: List<Map<String, dynamic>>.from(params['iceCandidates']),
      dtlsParameters: params['dtlsParameters'],
    );

    transport.on('connect', (options) {
      _socket.call('connectWebRtcTransport', {'transportId': transport.id, 'dtlsParameters': options.dtlsParameters});
    });

    transport.on('produce', (details) async {
      final producerId = await _socket.call('produce', {
        'transportId': transport.id,
        'kind': details.kind,
        'rtpParameters': details.rtpParameters,
      });
      details.callback(producerId);
    });

    return transport;
  }

  Future<RecvTransport> createRecvTransport(String classId) async {
    final params = await _socket.call('createWebRtcTransport', {
      'classId': classId,
      'producing': false,
      'consuming': true,
    });

    final transport = _device.createRecvTransport(
      id: params['id'],
      iceParameters: params['iceParameters'],
      iceCandidates: List<Map<String, dynamic>>.from(params['iceCandidates']),
      dtlsParameters: params['dtlsParameters'],
    );

    transport.on('connect', (options) {
      _socket.call('connectWebRtcTransport', {'transportId': transport.id, 'dtlsParameters': options.dtlsParameters});
    });

    return transport;
  }

  Future<Consumer> consume(RecvTransport transport, String producerId, RtpCapabilities rtpCapabilities) async {
    final params = await _socket.call('consume', {
      'transportId': transport.id,
      'producerId': producerId,
      'rtpCapabilities': rtpCapabilities,
    });

    final consumer = await transport.consume(
      id: params['id'],
      producerId: params['producerId'],
      kind: params['kind'],
      rtpParameters: RtpParameters.fromMap(params['rtpParameters']),
    );

    return consumer;
  }

  void dispose() {
    _socket.dispose();
  }
}
