import 'package:flutter/material.dart';

class Joystick extends StatefulWidget {
  final Function(num, num) onMove;
  final Function() stopMove;

  const Joystick({Key? key,
    required this.onMove,
    required this.stopMove,
  }) : super(key: key);

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  int mainR = 150;
  int maxDist = 0;
  int currentX = 0;
  int currentY = 0;
  int secR = 40;

  @override
  void initState(){
    super.initState();
    currentX = (mainR/2).toInt();
    currentY = (mainR/2).toInt();
    maxDist = (mainR/2).toInt() - (secR/2).toInt();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (data){
        setState(() {
          /// TODO: implement correct TG processing
          if((data.localPosition.dx - mainR/2)*(data.localPosition.dx - mainR/2)
              + (data.localPosition.dy - mainR/2)*(data.localPosition.dy - mainR/2) <= maxDist*maxDist){
            currentX = (data.localPosition.dx).toInt();
            currentY = (data.localPosition.dy).toInt();

            /// hooooook
            widget.onMove(currentX - mainR/2, mainR/2 - currentY);
          }
        });
      },
      onPanEnd: (data){
        setState(() {
          currentX = (mainR/2).toInt();
          currentY = (mainR/2).toInt();
        });

        /// hoook
        widget.stopMove();
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(mainR/2)),
            child: Container(
              width: mainR.toDouble(),
              height: mainR.toDouble(),
              color: Colors.black54.withOpacity(.3),
            ),
          ),
          Positioned(
              top: currentY- secR/2,
              left: currentX - secR/2,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(secR/2)),
                child: Container(
                  width: secR.toDouble(),
                  height: secR.toDouble(),
                  color: Colors.black54.withOpacity(.7),
                ),
              )
          )
        ]
      ),
    );
  }
}
