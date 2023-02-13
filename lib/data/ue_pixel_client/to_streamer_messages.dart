
enum UEProtocolStructure {
  int16,
  uint8,
  uint16,
  double,
}

class ToStreamerMessage {
  final int code;
  final int byteLength;
  final List<UEProtocolStructure> structure;

  ToStreamerMessage({
    required this.code,
    required this.byteLength,
    required this.structure,
  });

  // TODO: implement to bytes method
}

/// массив списан с app.js signallingWebServer, который предоставляет unreal
Map<String, ToStreamerMessage> toStreamerMessages = {
  /// Control Messages. Range = 0..49.
  "IFrameRequest": ToStreamerMessage(
    code: 0,
    byteLength: 0,
    structure: [],
  ),
  "RequestQualityControl": ToStreamerMessage(
    code: 1,
    byteLength: 0,
    structure: [],
  ),
  "FpsRequest": ToStreamerMessage(
    code: 2,
    byteLength: 0,
    structure: [],
  ),
  "AverageBitrateRequest": ToStreamerMessage(
    code: 3,
    byteLength: 0,
    structure: [],
  ),
  "StartStreaming": ToStreamerMessage(
    code: 4,
    byteLength: 0,
    structure: [],
  ),
  "StopStreaming": ToStreamerMessage(
    code: 5,
    byteLength: 0,
    structure: [],
  ),
  "LatencyTest": ToStreamerMessage(
      code: 6,
      byteLength: 0,
      structure: []
  ),
  "RequestInitialSettings": ToStreamerMessage(
    code: 7,
    byteLength: 0,
    structure: [],
  ),
  "TestEcho": ToStreamerMessage(
    code: 8,
    byteLength: 0,
    structure: [],
  ),

  /// Generic Input Messages. Range = 50..59.
  "UIInteraction": ToStreamerMessage(
    code: 50,
    byteLength: 0,
    structure: [],
  ),
  "Command": ToStreamerMessage(
    code: 51,
    byteLength: 0,
    structure: [],
  ),

  /// Keyboard Input Message. Range = 60..69.
  "KeyDown": ToStreamerMessage(
    code: 60,
    byteLength: 2,
    structure: [
      UEProtocolStructure.uint8, // key code
      UEProtocolStructure.uint8 // is repeat
    ],
  ),
  "KeyUp": ToStreamerMessage(
      code: 61,
      byteLength: 1,
      structure: [
        UEProtocolStructure.uint8 // key code
      ]
  ),
  "KeyPress": ToStreamerMessage(
      code: 62,
      byteLength: 2,
      structure: [
        UEProtocolStructure.uint16
      ]
  ),

  /// Mouse Input Messages. Range = 70..79.
  "MouseEnter": ToStreamerMessage(
      code: 70,
      byteLength: 0,
      structure: []
  ),
  "MouseLeave": ToStreamerMessage(
    code: 71,
    byteLength: 0,
    structure: [],
  ),
  "MouseDown": ToStreamerMessage(
      code: 72,
      byteLength: 5,
      structure: [
        UEProtocolStructure.uint8, // button
        UEProtocolStructure.uint16, // x
        UEProtocolStructure.uint16, // y
      ]
  ),
  "MouseUp": ToStreamerMessage(
      code: 73,
      byteLength: 5,
      structure: [
        UEProtocolStructure.uint8, // button
        UEProtocolStructure.uint16, // x
        UEProtocolStructure.uint16, // y
      ]
  ),
  "MouseMove": ToStreamerMessage(
      code: 74,
      byteLength: 8,
      structure: [
        UEProtocolStructure.uint16, // x
        UEProtocolStructure.uint16, // y
        UEProtocolStructure.int16, // deltaX,
        UEProtocolStructure.int16, // deltaY,
      ]
  ),
  "MouseWheel": ToStreamerMessage(
      code: 75,
      byteLength: 6,
      structure: [
        UEProtocolStructure.int16, // delta
        UEProtocolStructure.uint16, // x
        UEProtocolStructure.uint16 // y
      ]
  ),
  "MouseDouble": ToStreamerMessage(
      code: 76,
      byteLength: 6,
      structure: [
        UEProtocolStructure.uint8, // button
        UEProtocolStructure.uint16, // x
        UEProtocolStructure.uint16, // y
      ]
  ),

  /// Touch Input Messages. Range = 80..89.
  "TouchStart": ToStreamerMessage(
      code: 80,
      byteLength: 8,
      structure: [
        UEProtocolStructure.uint8, // num of touches
        UEProtocolStructure.uint16, // x
        UEProtocolStructure.uint16, // y
        UEProtocolStructure.uint8, // idx
        UEProtocolStructure.uint8, // force
        UEProtocolStructure.uint8, // valid
      ]
  ),
  "TouchEnd": ToStreamerMessage(
      code: 81,
      byteLength: 8,
      structure: [
        UEProtocolStructure.uint8, // num of touches
        UEProtocolStructure.uint16, // x
        UEProtocolStructure.uint16, // y
        UEProtocolStructure.uint8, // idx
        UEProtocolStructure.uint8, // force
        UEProtocolStructure.uint8, // valid
      ]
  ),
  "TouchMove": ToStreamerMessage(
      code: 82,
      byteLength: 8,
      structure: [
        UEProtocolStructure.uint8, // num of touches
        UEProtocolStructure.uint16, // x
        UEProtocolStructure.uint16, // y
        UEProtocolStructure.uint8, // idx
        UEProtocolStructure.uint8, // force
        UEProtocolStructure.uint8, // valid
      ]
  ),

  /// Gamepad Input Messages. Range = 90..99
  "GamepadButtonPressed": ToStreamerMessage(
      code: 90,
      byteLength: 3,
      structure: [
        UEProtocolStructure.uint8, // ctrlerID
        UEProtocolStructure.uint8, // button
        UEProtocolStructure.uint8 // isRepeat
      ]
  ),
  "GamepadButtonReleased": ToStreamerMessage(
      code: 91,
      byteLength: 3,
      structure: [
        UEProtocolStructure.uint8, // ctrlerID
        UEProtocolStructure.uint8, // button
        UEProtocolStructure.uint8 // isRepeat
      ]
  ),
  "GamepadAnalog": ToStreamerMessage(
    code: 92,
    byteLength: 10,
    structure: [
      UEProtocolStructure.uint8, // ctrlerId
      UEProtocolStructure.uint8, // button
      UEProtocolStructure.double, // analogValue
    ]
  ),
};