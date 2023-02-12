part of 'home_bloc.dart';

@immutable
class HomeState extends Equatable {
  /// переменная, содержащая "стрим"
  final RTCVideoRenderer remoteRenderer;

  /// для корректного вывода UI
  final HomePageStatus status;

  /// текст ошибки в случае фейл-статуса
  final String errorMessage;

  const HomeState({
    required this.remoteRenderer,
    this.status = HomePageStatus.menu,
    this.errorMessage = '',
  });

  /// для упрощенного создания других вариантов этого стейта
  HomeState copyWith({
    RTCVideoRenderer? remoteRenderer,
    HomePageStatus? status,
    String? errorMessage,
  }) {
    return HomeState(
      remoteRenderer: remoteRenderer ?? this.remoteRenderer,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// для equatable
  @override
  List<Object> get props => [remoteRenderer, status, errorMessage];
}