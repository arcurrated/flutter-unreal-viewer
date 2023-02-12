import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// код UIInteraction (специфика Unreal Engine)
const int DEFAULT_EVENT_CODE = 50;

class UePixelClient {
  /// signalling
  WebSocketChannel? channel;

  /// for WebRTC
  Map<String, dynamic> peerConnectionOptions = {};
  RTCPeerConnection? peerConnection;
  RTCDataChannel? dataChannel;

  /// for UE scene
  final double screenWidth;
  final double screenHeight;

  /// hooks
  final void Function(String) onError;
  final void Function(MediaStream) onSuccess;

  UePixelClient({
    required this.screenWidth,
    required this.screenHeight,
    required this.onError,
    required this.onSuccess,
  });

  Future<void> connect(String signallingURI) async {
    try {
      channel = WebSocketChannel.connect(Uri.parse('ws://$signallingURI'));
      channel?.stream.listen((data) async {
        var tmp = jsonDecode(data);
        var tag = tmp['type'];
        onSignallingMessage(tag, data);
      }, onError: (e){
        onError(e.toString());
      });
    } catch(e) {
      onError(e.toString());
    }
  }

  /// метод предназначен для обработки сообщений от signalling сервера
  /// большая часть кода обеспечивает работу WebRTC
  void onSignallingMessage(String tag, message) async {
    switch (tag) {
    /// config - setup STUN, TURN and other
      case 'config': {
        /// message = { 'type': 'config', 'peerConnectionOptions': { 'iceServer': ... } }
        var tmp = jsonDecode(message);
        if(tmp['peerConnectionOptions'] != null){
          peerConnectionOptions = tmp['peerConnectionOptions'];
        }
        peerConnectionOptions['sdpSemantics'] = 'unified-plan';
        peerConnectionOptions['offerExtmapAllowMixed'] = false;
        peerConnectionOptions['bundlePolicy'] = 'max-bundle';
      }
      break;

      case 'offer': {
        peerConnection = await createPeerConnection(
            peerConnectionOptions.isEmpty ? {} : peerConnectionOptions
        );
        peerConnection!.onIceCandidate = (candidate) {
          final iceCandidate = {
            'sdpMLineIndex': candidate.sdpMLineIndex,
            'sdpMid': candidate.sdpMid,
            'candidate': candidate.candidate,
          };
          emitIceCandidateEvent(iceCandidate);
        };

        peerConnection!.onDataChannel = (channel){
          dataChannel = channel;
          dataChannel!.onDataChannelState = (state){
            print('change state: ${state.toString()}');
          };

          /// установить размеры картинки со сцены, чтобы вписалась в экран
          /// устройства (делает unreal engine по коду события 51 (команда))
          /// чтобы работали команды, при запуске сцены добавить флаг
          /// -AllowPixelStreamingCommands=true
          /// остальные коды можно увидеть в коде .js файлов SignallingServer
          sendToChannel({
            "Resolution.Width": screenWidth,
            "Resolution.Height": screenHeight
          }, 51);
        };

        peerConnection!.onTrack = (RTCTrackEvent event) {
          print('receive track');
          if (event.track.kind == 'video') {
            print('receive video track');

            /// вызов хука, когда получаем стрим для последующего вывода на экран
            onSuccess(event.streams[0]);
          }
        };

        var tmp = jsonDecode(message);
        await peerConnection!.addTransceiver(
            kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
            init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly)
        );
        await peerConnection!.setRemoteDescription(
            RTCSessionDescription(tmp['sdp'], tmp['type']));
        RTCSessionDescription answer = await peerConnection!.createAnswer();
        peerConnection!.setLocalDescription(answer);
        emitAnswerEvent(answer.toMap());
      }
      break;

      case 'answer': {
        await peerConnection?.setRemoteDescription(
            RTCSessionDescription(message['sdp'], message['type']));
      }
      break;
      case 'iceCandidate': {
        var candidateMap = message;
        var tmpCandidate = jsonDecode(candidateMap);
        var candidateObject = tmpCandidate["candidate"];
        RTCIceCandidate candidate = RTCIceCandidate(
            candidateObject["candidate"],
            candidateObject['sdpMid'],
            candidateObject['sdpMLineIndex']);
        peerConnection?.addCandidate(candidate);
      }
      break;
    }
  }

  /// метод относится к каскаду функций для корректной работы WebRTC
  void emitIceCandidateEvent(candidate){
    Map<String, dynamic> data = {'type': 'iceCandidate', 'candidate': candidate};
    _sendToSignalling(jsonEncode(data));
  }
  /// метод относится к каскаду функций для корректной работы WebRTC
  emitAnswerEvent(description) {
    Map<String, dynamic> data = {"type" : 'answer', "sdp" : description['sdp'] };
    _sendToSignalling(jsonEncode(data));
  }

  /// метод предназначен для отправки данных на сигналлинг сервер
  void _sendToSignalling(String data){
    channel?.sink.add(data);
  }

  /// метод необходим для того, чтобы корректно завершить
  void down() async {
    peerConnection?.close();
    dataChannel?.close();
    channel?.sink.close();
  }

  /// метод необходим для передачи информации по WebRTC каналу (сцене)
  /// алгоритм задан unrealEngine (специфика)
  void sendToChannel(Map<String, dynamic> _sendObj, int eventCode){
    if(dataChannel == null){
      return;
    }
    String _sendStr = jsonEncode(_sendObj);

    ByteData data = ByteData(3 + 2*_sendStr.length);

    int counter = 0;
    /// в первый байт устанавливаем код команды
    data.setUint8(counter, eventCode);
    counter += 1;

    /// во следующие два байта записываем длину сообщения
    data.setUint16(counter, _sendStr.length, Endian.little);
    counter += 2;

    /// далее каждый символ преобразуем в число (код символа) и занимаем
    /// каждые следующие два байта
    for(int i = 0; i < _sendStr.length; i++){
      data.setUint16(counter, _sendStr.codeUnitAt(i), Endian.little);
      counter += 2;
    }

    /// отправляем
    dataChannel!.send(RTCDataChannelMessage.fromBinary(
        data.buffer.asUint8List()
    ));
  }
}