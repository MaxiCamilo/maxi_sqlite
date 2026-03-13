import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sqlite/src/enginer/sqlite_connector.dart';
import 'package:maxi_sqlite/src/enginer/sqlite_data_connector.dart';
import 'package:maxi_sqlite/src/enginer/sqlite_mutex.dart';
import 'package:maxi_sqlite/src/models/sqlite_command.dart';

class SqliteTransaction with DisposableMixin, AsynchronouslyInitializedMixin implements SqlTransaction, SqliteMutex {
  final SqliteMutex reserver;

  final _mutex = Mutex();

  bool _confirmed = false;
  bool _wasCommitted = false;
  late SqliteConnector _adapter;

  @override
  bool get confirmed => _confirmed;

  @override
  bool get wasCommitted => _wasCommitted;

  @override
  bool get isActive => !itWasDiscarded;

  SqliteTransaction({required this.reserver});

  @override
  Future<Result<void>> performInitialize() async {
    if (LifeCoordinator.isZoneHeartCanceled) {
      return CancelationResult();
    }

    if (_confirmed) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: const FixedOration(message: 'The transaction is already confirmed'),
      );
    }

    final adaptResult = await reserver.connect();
    if (adaptResult.itsFailure) {
      return adaptResult.cast();
    }

    _adapter = adaptResult.content;

    return _adapter
        .executeCommand(
          command: const SqliteCommand(sql: 'BEGIN TRANSACTION;', parameters: []),
        )
        .injectNegativeLogic((_) => reserver.release());
  }

  @override
  void performInitializedObjectDiscard() {
    super.performInitializedObjectDiscard();
    reserver.release();
  }

  @override
  FutureResult<SqlTransaction> beginTransaction() async => asResultValue();

  @override
  SqlDataConnector buildDataConnector() => SqliteDataConnector(reserver: this);

  @override
  SqlStructure buildStructureManager() {
    // TODO: implement buildStructureManager
    throw UnimplementedError();
  }

  @override
  FutureResult<void> commit() async {
    if (_confirmed) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: const FixedOration(message: 'The transaction is already confirmed'),
      );
    }

    final exeResult = await _adapter.executeCommand(
      command: const SqliteCommand(sql: 'COMMIT;', parameters: []),
    );

    _confirmed = true;
    _wasCommitted = true;
    dispose();
    if (exeResult.itsFailure) {
      return exeResult.cast();
    }

    return voidResult;
  }

  @override
  FutureResult<void> rollback() async {
    if (_confirmed) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: const FixedOration(message: 'The transaction is already confirmed'),
      );
    }

    final exeResult = await _adapter.executeCommand(
      command: const SqliteCommand(sql: 'ROLLBACK;', parameters: []),
    );

    _confirmed = true;
    _wasCommitted = false;
    dispose();
    if (exeResult.itsFailure) {
      return exeResult.cast();
    }

    return voidResult;
  }

  @override
  FutureResult<SqliteConnector> connect() => initialize().onCorrectFuture((_) => _adapter.asResultValue());

  @override
  FutureResult<T> execute<T>(FutureResult<T> Function(SqliteConnector) function) => initialize().onCorrectFuture((_) async {
    if (LifeCoordinator.isZoneHeartCanceled) {
      return CancelationResult();
    }
    return _mutex.execute(() => function(_adapter));
  });

  @override
  void release() {}
}
