import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_sql/maxi_sql.dart';
import 'package:maxi_sqlite/src/enginer/sqlite_data_connector.dart';
import 'package:maxi_sqlite/src/enginer/sqlite_reserver.dart';
import 'package:maxi_sqlite/src/enginer/sqlite_structure.dart';
import 'package:maxi_sqlite/src/enginer/sqlite_transaction.dart';
import 'package:maxi_sqlite/src/models/sqlite_configuration.dart';

class SqliteEngine with DisposableMixin implements SqlEngine, AsynchronouslyInitialized {
  final SqliteConfiguration configuration;

  late final SqliteReserver _reserver;

  @override
  bool get isActive => !itWasDiscarded;

  SqliteEngine({required this.configuration}) {
    _reserver = SqliteReserver(configuration: configuration);
  }

  @override
  SqlDataConnector buildDataConnector() => SqliteDataConnector(reserver: _reserver);

  @override
  SqlStructure buildStructureManager() => SqliteStructure(mutex: _reserver);

  @override
  FutureResult<SqlTransaction> beginTransaction() async {
    final tran = SqliteTransaction(reserver: _reserver);
    return tran.initialize().injectNegativeLogic((_) => tran.dispose).onCorrectFuture((_) => tran.asResultValue());
  }

  @override
  void performObjectDiscard() {
    _reserver.dispose();
  }

  @override
  bool get isInitialized => _reserver.isInitialized;

  @override
  Future<Result<void>> initialize() => _reserver.initialize();
}
