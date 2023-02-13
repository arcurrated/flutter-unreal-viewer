import 'dart:convert';
import 'dart:typed_data';

/// перечисление доступных для преобразования в байты типов передаваемых
/// значений
enum UEProtocolStructure {
  int16,
  uint8,
  uint16,
  double,
}

/// возможно несколько вариантов преобразования входных данных в байты:
/// 1. только код сообщения
/// 2. код и дополнительная информацияв строгом порядке с соблюдением типов
///   (которые берутся из structure)
/// 3. код и JSON строка посимвольно сконвертированная в байты
enum UEMessageMode {
  strictProto,
  json,
  onlyCode,
}

/// класс для сообщений стримеру (сцене unreal)
/// включает специфику протокола преобразования данных
/// согласно js-файлам предоставляемого плеера
class ToStreamerMessage {
  final int code;
  final int byteLength;
  final List<UEProtocolStructure> structure;
  final UEMessageMode mode;

  ToStreamerMessage({
    required this.code,
    required this.byteLength,
    required this.structure,
    this.mode = UEMessageMode.strictProto,
  });

  /// метод, преобразующий данные, которые необходимо передать сцене
  /// включая команду в набор байт, соответствующий спецификации unreal pixel
  /// streaming
  ByteData toBytes(dynamic args){
    /// определение длины окончательного набора байт
    int len = byteLength + 1;
    if(mode == UEMessageMode.json){
      /// для динамических сообщений
      len = 3 + 2*jsonEncode(args).length;
    }

    ByteData resp = ByteData(len);
    int byteOffset = 0;
    /// в первый байт устанавливаем код команды
    resp.setUint8(byteOffset, code);

    byteOffset++;

    if(mode == UEMessageMode.strictProto){
      List<dynamic> inData = args as List<dynamic>;

      inData.asMap().forEach((index, value) {
        switch(structure[index]){
          case UEProtocolStructure.uint8:
            int val = 0;
            if(value is bool){
              val = value ? 1 : 0;
            } else if(value is double){
              val = value.toInt();
            } else {
              val = value;
            }
            resp.setUint8(byteOffset, val);
            byteOffset++;
            break;
          case UEProtocolStructure.uint16:
            resp.setUint16(byteOffset, value is double ? value.toInt() : value, Endian.little);
            byteOffset += 2;
            break;
          case UEProtocolStructure.int16:
            resp.setInt16(byteOffset, value is double ? value.toInt() : value, Endian.little);
            byteOffset += 2;
            break;
          case UEProtocolStructure.double:
            resp.setFloat64(byteOffset, value, Endian.little);
            byteOffset += 8;
            break;
        }
      });
    } else if(mode == UEMessageMode.json){
      String _sendStr = jsonEncode(args);

      /// во следующие два байта записываем длину сообщения
      resp.setUint16(byteOffset, _sendStr.length, Endian.little);
      byteOffset += 2;

      /// далее каждый символ преобразуем в число (код символа) и занимаем
      /// каждые следующие два байта
      for(int i = 0; i < _sendStr.length; i++){
        resp.setUint16(byteOffset, _sendStr.codeUnitAt(i), Endian.little);
        byteOffset += 2;
      }
    }

    /// возвращаем байты для последующей отправки сцене
    return resp;
  }
}