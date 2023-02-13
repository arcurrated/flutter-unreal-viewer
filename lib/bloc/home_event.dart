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

/// событие, вызываемое при обновлении перемещении касания по экрану
class PanUpdateEvent extends HomeEvent {
  final double dx;
  final double dy;

  const PanUpdateEvent(this.dx, this.dy);

  @override
  List<Object?> get props => [dx, dy];
}

/// вызывается с UI при повороте экрана
class NewDimensionsEvent extends HomeEvent {
  final double width;
  final double height;

  const NewDimensionsEvent(this.width, this.height);

  @override
  List<Object?> get props => [width, height];
}

/// вызывается с UI для перемещений
class MoveEvent extends HomeEvent {
  final num x;
  final num y;

  const MoveEvent(this.x, this.y);

  @override
  List<Object?> get props => [x, y];
}

/// release joystick
class StopMoveEvent extends HomeEvent {
  const StopMoveEvent();

  @override
  List<Object?> get props => [];
}

/// jump )))
class JumpEvent extends HomeEvent {
  const JumpEvent();

  @override
  List<Object?> get props => [];
}