import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../data/ue_pixel_client/ue_pixel_client.dart';
import '../models/models.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  /// интерфейс на AR модуль data слоя
  /// (сигналлинг, этот же дата слой занимается отправкой данных с датчиков,
  /// а так же изменением года)
  UePixelClient? ueInterface;

  /// переменная вывода
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  /// для UE scene
  final double screenWidth;
  final double screenHeight;

  HomeBloc(this.screenWidth, this.screenHeight) : super(HomeState(remoteRenderer: RTCVideoRenderer())) {
    /// при событии с UI передается хост и порт сигналлинга
    on<SignallingServerDataEvent>((event, emit) {
      ueInterface?.connect(event.hostPort);
      emit(state.copyWith(
        status: HomePageStatus.loading,
      ));
    });

    /// при загрузке необходимо обновить статус и передать обновленный renderer
    on<PixelStreamingLoadedEvent>((event, emit) {
      remoteRenderer.srcObject = event.stream;

      emit(state.copyWith(
        status: HomePageStatus.loaded,
        remoteRenderer: remoteRenderer,
      ));
    });

    /// обновить статус
    on<PixelStreamingFailedEvent>((event, emit) {
      emit(state.copyWith(
        status: HomePageStatus.failed,
        errorMessage: event.message,
      ));
    });

    /// при событии c UI закрытия дернуть дата-слой
    on<PixelStreamingDisconnectEvent>((event, emit) {
      ueInterface?.down();
      /// выход в меню с обнулением remoteRenderer
      emit(state.copyWith(
        status: HomePageStatus.menu,
        remoteRenderer: remoteRenderer,
      ));
    });

    on<ToMenuEvent>((event, emit) {
      emit(state.copyWith(
        status: HomePageStatus.menu,
      ));
    });

    /// при перемещении касания по экрану
    on<PanUpdateEvent>((event, emit) {
      ueInterface?.sendMessageToStreamer('MouseMove',
        [65535, 65535, event.dx*100, event.dy*100]
      );
    });

    /// при повороте экрана
    on<NewDimensionsEvent>((event, emit) {
      ueInterface?.sendMessageToStreamer("Command", {
        "Resolution.Width": event.width.toInt(),
        "Resolution.Height": event.height.toInt()
      });
    });

    /// отработать сигнал перемещения
    on<MoveEvent>((event, emit) {
      // todo: отдебажить (определить сектора, иначе сейчас он только по диагонали бегает)
      if(event.x > 0){
        /// key arrow left - 39
        ueInterface?.sendMessageToStreamer("KeyDown", [39, false]);
        ueInterface?.sendMessageToStreamer("KeyUp", [37]);
      } else {
        /// key arrow right - 37
        ueInterface?.sendMessageToStreamer("KeyDown", [37, false]);
        ueInterface?.sendMessageToStreamer("KeyUp", [39]);
      }
      if(event.y > 0){
        /// key arrow up - 38
        ueInterface?.sendMessageToStreamer("KeyDown", [38, false]);
        ueInterface?.sendMessageToStreamer("KeyUp", [40]);
      } else {
        /// key arrow down - 40
        ueInterface?.sendMessageToStreamer("KeyUp", [38]);
        ueInterface?.sendMessageToStreamer("KeyDown", [40, false]);
      }
    });

    /// прекратить движение (отпустить джойстик)
    on<StopMoveEvent>((event, emit) {
      ueInterface?.sendMessageToStreamer("KeyUp", [37]);
      ueInterface?.sendMessageToStreamer("KeyUp", [38]);
      ueInterface?.sendMessageToStreamer("KeyUp", [39]);
      ueInterface?.sendMessageToStreamer("KeyUp", [40]);
    });

    on<JumpEvent>((event, emit) {
      ueInterface?.sendMessageToStreamer("KeyDown", [32, false]);
      Future.delayed(const Duration(milliseconds: 20), (){
        ueInterface?.sendMessageToStreamer("KeyUp", [32]);
      });
    });

    ueInterface = UePixelClient(
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        onError: (String error){
          add(PixelStreamingFailedEvent(message: error));
        },
        /// успешным результатом будет получение стрима WebRTC
        onSuccess: (MediaStream stream){
          add(PixelStreamingLoadedEvent(stream));
        }
    );
    remoteRenderer.initialize();
  }
}