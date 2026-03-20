import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sqlite/src/enginer/sqlite_connector.dart';
import 'package:maxi_sqlite/src/enginer/sqlite_mutex.dart';
import 'package:maxi_sqlite/src/models/sqlite_configuration.dart';

class SqliteReserver with DisposableMixin, AsynchronouslyInitializedMixin implements SqliteMutex {
  final SqliteConfiguration configuration;

  final _idleTimer = MaxiTimer();
  final _mutex = Mutex();

  late SqliteConnector _adapter;

  Completer<void>? _waiter;

  SqliteReserver({required this.configuration});

  @override
  Future<Result<void>> performInitialize() async {
    if (LifeCoordinator.isZoneHeartCanceled) {
      final cancel = CancelationResult();
      appManager.exceptionChannel.sendItem((cancel, StackTrace.current));
      return cancel;
    }

    _adapter = SqliteConnector(configuration: configuration);
    final initResult = await _adapter.initialize();
    if (initResult.itsFailure) {
      return initResult;
    } /*
    if (configuration.idleTimeout != null) {
      _idleTimer.startOrReset(duration: configuration.idleTimeout!, payload: null, onFinish: (_) => dispose());
    }*/
    return voidResult;
  }

  @override
  FutureResult<SqliteConnector> connect() {
    return initialize().onCorrectFuture((_) {
      return _mutex.execute(() async {
        if (_waiter != null) {
          await _waiter!.future;
        }

        _idleTimer.cancel();
        _waiter = Completer<void>();
        return _adapter.asResultValue();
      });
    });
  }

  @override
  void release() {
    if (_waiter != null) {
      _waiter!.complete();
      _waiter = null;
    }

    if (itWasDiscarded) {
      return;
    }

    if (configuration.idleTimeout != null) {
      _idleTimer.startOrReset(duration: configuration.idleTimeout!, payload: null, onFinish: (_) => dispose());
    }
  }

  @override
  FutureResult<T> execute<T>(FutureResult<T> Function(SqliteConnector) function) async {
    return connect().onCorrectFuture(function).whenComplete(() => release());
  }
}
