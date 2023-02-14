import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_unreal_viewer/view/joystick_widget.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../bloc/home_bloc.dart';
import '../models/models.dart';
import 'dart:ui';

class HomePage extends StatelessWidget with WidgetsBindingObserver {
  HomePage({Key? key}) : super(key: key);

  final _hostPortController = TextEditingController();

  /// хук для изменения разрешения стрима
  Function(double, double)? onChangeMetrics;

  @override void didChangeMetrics() {
    /// если такой хук есть
    if(onChangeMetrics != null){
      /// вызвать хук для изменения размера стрима
      onChangeMetrics!(window.physicalSize.width, window.physicalSize.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);
    /// calc screen dimensions for correct view
    double ratio = MediaQuery.of(context).devicePixelRatio;
    double height = MediaQuery.of(context).size.height * ratio;
    double width = MediaQuery.of(context).size.width * ratio;

    return Scaffold(
      body: BlocProvider<HomeBloc>(
        create: (context){
          return HomeBloc(width, height);
        },
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state){
            /// установить хук для изменения разрешения стрима
            onChangeMetrics = (double width, double height){
              context.read<HomeBloc>().add(NewDimensionsEvent(width, height));
            };
            return Stack(
                children: [
                  Container(
                      color: Colors.black54,
                      child: GestureDetector(
                          onPanUpdate: (details) {
                            context.read<HomeBloc>().add(PanUpdateEvent(
                              details.delta.dx,
                              details.delta.dy
                            ));
                          },
                          onTap: (){
                            context.read<HomeBloc>().add(const JumpEvent());
                          },
                          child: RTCVideoView(state.remoteRenderer)
                      )
                  ),
                  state.status != HomePageStatus.loaded ? Container(
                    color: Colors.black.withOpacity(0.6),
                    child: SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 50),
                              GestureDetector(
                                onTap: (){
                                  FocusScope.of(context).unfocus();
                                },
                                child: const Text('Введите IP и порт SignallingServer:',
                                  style: TextStyle(
                                    color: Colors.white60,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8,),
                              TextField(
                                decoration: const InputDecoration(
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white24,
                                    ),
                                    borderRadius: BorderRadius.all(Radius.circular(15)),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(15)),
                                  ),
                                  hintText: "0.0.0.0:8888",
                                  hintStyle: TextStyle(
                                    color: Colors.white24,
                                  )
                                ),
                                style: const TextStyle(
                                  color: Colors.white54,
                                ),
                                controller: _hostPortController,
                              ),
                              const SizedBox(height: 16,),
                              ElevatedButton(
                                onPressed: (){
                                  if(_hostPortController.text.isEmpty){
                                    return;
                                  }
                                  context.read<HomeBloc>().add(SignallingServerDataEvent(
                                    _hostPortController.text
                                  ));
                                },
                                child: state.status == HomePageStatus.loading ?
                                  const CupertinoActivityIndicator() :
                                  const Text('Подключиться'),
                              ),
                              const SizedBox(height: 16,),
                              if(state.status == HomePageStatus.failed)
                                Text('Error: ${state.errorMessage}',)
                            ],
                          ),
                        )
                      ),
                    )
                  ) : const SizedBox(),

                  if(state.status == HomePageStatus.loaded)
                    Container(
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: (){
                                  context.read<HomeBloc>().add(PixelStreamingDisconnectEvent());
                                },
                                child: const Text('Disconnect'),
                              ),
                            ],
                          )
                        ),
                      )
                    ),
                  state.status == HomePageStatus.loaded ? Positioned(
                    bottom: 20,
                    left: 20,
                    child: Joystick(onMove: (num x, num y){
                      context.read<HomeBloc>().add(MoveEvent(x, y));
                    }, stopMove: (){
                      context.read<HomeBloc>().add(const StopMoveEvent());
                    },)
                  ) : const SizedBox(),
                ],
              );
          },
        ),
      ),
    );
  }
}
