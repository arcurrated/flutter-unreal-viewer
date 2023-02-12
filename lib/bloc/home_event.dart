part of 'home_bloc.dart';

@immutable
abstract class HomeEvent extends Equatable{
  const HomeEvent();
}

/// событие, которое сгенерит UI при вводе данных сигналлинга
class SignallingServerDataEvent extends HomeEvent {
  /// 192.168.0.2:8886
  final String hostPort;

  const SignallingServerDataEvent(this.hostPort);

  @override
  List<Object> get props => [hostPort];
}

/// событие, которое сгенерит блок при хуке успешного коннекта с data слоя
class PixelStreamingLoadedEvent extends HomeEvent {
  final MediaStream stream;

  const PixelStreamingLoadedEvent(this.stream);

  @override
  List<Object?> get props => [stream];
}

/// событие, которое сгенерит блок при хуке ошибки с data слоя
class PixelStreamingFailedEvent extends HomeEvent {
  final String message;

  const PixelStreamingFailedEvent({
    this.message = ''
  });

  @override
  List<Object?> get props => [message];
}

/// событие, которое сгенерит UI при нажатии на кнопку выхода
class PixelStreamingDisconnectEvent extends HomeEvent {
  const PixelStreamingDisconnectEvent();

  @override
  List<Object?> get props => [];
}

/// событие, вызываемое с UI для открытия меню
class ToMenuEvent extends HomeEvent {
  const ToMenuEvent();

  @override
  List<Object?> get props => [];
}