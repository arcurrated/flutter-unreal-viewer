import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'to_streamer_messages.dart';

/// todo: implement method sendMessageToStreamer associated with protocol description

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
          sendMessageToStreamer("Command", {
            "Resolution.Width": screenWidth,
            "Resolution.Height": screenHeight
          });
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

  /// метод, предназначеный для отправки UIInteraction на unrealEngine
  /// именно через этот метод можно отправить кастомные данные
  /// и кастомно их обработать на стороне дижка
  void emitUIInteraction(Map<String, dynamic> data) {
    /// код UIInteraction - 50 (специфика Unreal Engine)
    sendToChannel(toStreamerMessages['UIInteraction']!.toBytes(data));
  }

  void sendMessageToStreamer(String messageType, dynamic inData){
    if(toStreamerMessages[messageType] == null){
      print('No such messageType: $messageType');
      return;
    }
    sendToChannel(
      toStreamerMessages[messageType]!.toBytes(inData ?? [])
    );
  }

  /// generic-метод для отправки двоичных данных сцене
  /// нужен, так как на нем заканчиваются два режима отправки данных
  /// (JSON и строго запротоколированный)
  sendToChannel(ByteData data){
    if(dataChannel == null){
      return;
    }

    dataChannel!.send(RTCDataChannelMessage.fromBinary(
      data.buffer.asUint8List()
    ));
  }
}