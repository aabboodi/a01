import 'dart:async';
import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class MediasoupService {
  Device? _device;
  io.Socket? _socket;

  RtpCapabilities? get rtpCapabilities => _device?.rtpCapabilities;

  Future<void> connect(String classId) async {
    _socket = io.io('http://10.0.2.2:3000/mediasoup', io.OptionBuilder().setTransports(['websocket']).build());

    final completer = Completer();
    _socket!.onConnect((_) => completer.complete());
    _socket!.connect();
    await completer.future;

    final data = await _emitWithAck('getRouterRtpCapabilities', {'classId': classId});
    final routerRtpCapabilities = RtpCapabilities.fromMap(data);

    _device = Device();
    await _device!.load(routerRtpCapabilities: routerRtpCapabilities);
  }

  Future<dynamic> createSendTransport(String classId) async {
    final params = await _emitWithAck('createWebRtcTransport', {'classId': classId, 'producing': true});
    final transport = _device!.createSendTransport(
      id: params['id'],
      iceParameters: IceParameters.fromMap(params['iceParameters']),
      iceCandidates: (params['iceCandidates'] as List).map((e) => IceCandidate.fromMap(e)).toList(),
      dtlsParameters: DtlsParameters.fromMap(params['dtlsParameters']),
    );

    transport.on('connect', (options) {
      _emitWithAck('connectWebRtcTransport', {'transportId': transport.id, 'dtlsParameters': options.dtlsParameters.toMap()});
    });

    transport.on('produce', (details) async {
      final result = await _emitWithAck('produce', {
        'transportId': transport.id,
        'kind': details.kind.name,
        'rtpParameters': details.rtpParameters.toMap(),
      });
      details.callback(result['id']);
    });
    return transport;
  }

  // ... other methods will be added once this is stable

  Future<dynamic> _emitWithAck(String event, dynamic data) {
    final completer = Completer();
    _socket!.emitWithAck(event, data, ack: (ackData) {
      completer.complete(ackData);
    });
    return completer.future;
  }

  void dispose() {
    _socket?.dispose();
  }
}
