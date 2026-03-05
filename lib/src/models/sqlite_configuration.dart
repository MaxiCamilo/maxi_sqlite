import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sqlite/src/enginer/sqlite_engine.dart';

class SqliteConfiguration implements SqlConfiguration {
  final bool isMemoryDB;
  final String filePath;
  final Duration? busyTimeout;
  final Duration? idleTimeout;

  const SqliteConfiguration._({required this.isMemoryDB, required this.filePath, required this.busyTimeout, required this.idleTimeout});

  factory SqliteConfiguration.memory({Duration? busyTimeout, Duration? idleTimeout}) {
    return SqliteConfiguration._(isMemoryDB: true, filePath: ':memory:', busyTimeout: busyTimeout, idleTimeout: idleTimeout);
  }

  factory SqliteConfiguration.file({required String filePath, Duration? busyTimeout, Duration? idleTimeout}) {
    return SqliteConfiguration._(isMemoryDB: false, filePath: filePath, busyTimeout: busyTimeout, idleTimeout: idleTimeout);
  }

  @override
  SqlEngine buildEngine() => SqliteEngine(configuration: this);
}
