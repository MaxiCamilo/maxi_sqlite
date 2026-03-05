import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sqlite/src/enginer/sqlite_connector.dart';

abstract interface class SqliteMutex implements Disposable {
  FutureResult<SqliteConnector> connect();

  void release();

  FutureResult<T> execute<T>(FutureResult<T> Function(SqliteConnector) function);
}
