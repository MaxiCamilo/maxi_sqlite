import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sqlite/src/logic/check_sqlfile_exists.dart';
import 'package:maxi_sqlite/src/models/sqlite_command.dart';
import 'package:maxi_sqlite/src/models/sqlite_configuration.dart';
import 'package:sqlite3/sqlite3.dart';

class SqliteConnector with DisposableMixin, AsynchronouslyInitializedMixin {
  final SqliteConfiguration configuration;

  String? _realPath;

  Database? _instance;

  SqliteConnector({required this.configuration});

  @override
  Future<Result<void>> performInitialize() async {
    try {
      if (configuration.isMemoryDB) {
        _instance = sqlite3.openInMemory();
      } else {
        final openResult = await _openFile();
        if (openResult.itsFailure) return openResult;
      }
    } catch (ex, st) {
      return ExceptionResult(
        exception: ex,
        stackTrace: st,
        message: FlexibleOration(
          message: 'An error occurred while opening the SQLite database located at %1. Please verify that the database is not in use by another process or is not corrupted',
          textParts: [_realPath!],
        ),
      );
    }

    return voidResult;
  }

  FutureResult<void> _openFile() async {
    if (_realPath == null) {
      final pathResult = await FileReference.interpretRoute(
        route: configuration.filePath,
        isLocal: false,
      ).onCorrect((x) => x.buildOperator().asResultValue<FileOperator>()).onCorrectFuture((x) => x.obtainCompleteRoute());
      if (pathResult.itsFailure) {
        return pathResult.cast();
      }
      _realPath = pathResult.content;
    }
    final checkExists = await CheckSqlfileExists(path: _realPath!).execute();
    if (checkExists.itsFailure) {
      return checkExists.cast();
    }
    final result = volatileFunction(
      error: (ex, st) => ExceptionResult(
        exception: ex,
        stackTrace: st,
        message: FlexibleOration.sensible(
          debugOration: FlexibleOration(message: 'An error occurred while trying to access the SQLite database file located at %1. Please verify that the file exists and is accessible', textParts: [_realPath!]),
          productionOration: const FixedOration(message: 'An error occurred while trying to access the database file. Please verify that the file exists and is accessible'),
        ),
      ),
      function: () => sqlite3.open(_realPath!),
    );

    if (result.itsFailure) {
      return result.cast();
    }
    _instance = result.content;
    return voidResult;
  }

  FutureResult<void> executeCommand({required SqliteCommand command}) async {
    final initResult = await initialize();
    if (initResult.itsFailure) {
      return initResult.cast();
    }

    return volatileFunction(
      error: (ex, st) => ExceptionResult(
        exception: ex,
        stackTrace: st,
        message: FlexibleOration.sensible(
          debugOration: FlexibleOration(message: 'An error occurred while executing the SQL command: %1. Please verify that the command is correct and that the database is not corrupted', textParts: [command.sql]),
          productionOration: const FixedOration(message: 'An error occurred while executing the command on the database. Please verify that the command is correct and that the database is not corrupted'),
        ),
      ),
      function: () => _instance!.execute(command.sql, command.parameters),
    );
  }

  FutureResult<TableResult> executeQuery({required SqliteCommand command}) async {
    final initResult = await initialize();
    if (initResult.itsFailure) {
      return initResult.cast();
    }

    final result = volatileFunction(
      error: (ex, st) => ExceptionResult(
        exception: ex,
        stackTrace: st,
        message: FlexibleOration.sensible(
          debugOration: FlexibleOration(message: 'An error occurred while executing the SQL query: %1. Please verify that the query is correct and that the database is not corrupted', textParts: [command.sql]),
          productionOration: const FixedOration(message: 'An error occurred while executing the query on the database. Please verify that the query is correct and that the database is not corrupted'),
        ),
      ),
      function: () => _instance!.select(command.sql, command.parameters),
    );

    if (result.itsFailure) {
      return result.cast();
    }

    return TableResult.withColumnsAndValues(columnsName: result.content.columnNames, values: result.content.rows).asResultValue();
  }

  @override
  void performInitializedObjectDiscard() {
    super.performInitializedObjectDiscard();

    _instance?.close();
    _instance = null;
  }
}
