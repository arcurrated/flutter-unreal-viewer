import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../bloc/home_bloc.dart';
import '../models/models.dart';

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  final _hostPortController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
            return Stack(
                children: [
                  Container(
                      child: RTCVideoView(state.remoteRenderer)
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
                    )
                ],
              );
          },
        ),
      ),
    );
  }
}
