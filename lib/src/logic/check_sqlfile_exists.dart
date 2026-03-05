import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';

class CheckSqlfileExists with FunctionalityMixin<void> {
  final String path;

  const CheckSqlfileExists({required this.path});

  @override
  Future<Result<void>> runFuncionality() async {
    final fileOperatorResult = FileReference.interpretRoute(route: path, isLocal: false);
    if (fileOperatorResult.itsFailure) return fileOperatorResult.cast();

    final fileOperator = fileOperatorResult.content.buildOperator();
    final fileExistsResult = await fileOperator.exists();
    if (fileExistsResult.itsFailure || fileExistsResult.content) return fileExistsResult.cast();

    return await fileOperator.create();
  }
}
