import 'dart:typed_data';

import 'package:maxi_framework/maxi_framework.dart';

class DistillParameters implements SyncFunctionality<List> {
  final List rawValues;

  const DistillParameters({required this.rawValues});

  static const List<Type> _primitiveTypes = [int, double, String, bool, List<int>, Uint8List];

  @override
  Result<List<dynamic>> execute() {
    final resultList = [];

    for (final item in rawValues) {
      if (_primitiveTypes.contains(item.runtimeType)) {
        resultList.add(item);
      } else if (item is Enum) {
        resultList.add(item.index);
      } else if (item is DateTime) {
        resultList.add(item.toUtc().millisecondsSinceEpoch);
      } else {
        return NegativeResult(
          error: ControlledFailure(
            errorCode: ErrorCode.wrongType,
            message: FlexibleOration(message: 'The value %1 is of type %2, which is not supported as a parameter', textParts: [item, item.runtimeType]),
          ),
        );
      }
    }

    return ResultValue(content: resultList);
  }
}
