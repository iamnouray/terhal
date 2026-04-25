import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../data/datasources/terhal_remote_datasource.dart';
import '../../data/repositories/terhal_repository_impl.dart';
import '../../domain/repositories/terhal_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final terhalRemoteDataSourceProvider = Provider<TerhalRemoteDataSource>((ref) {
  return TerhalRemoteDataSource(ref.watch(apiClientProvider));
});

final terhalRepositoryProvider = Provider<TerhalRepository>((ref) {
  return TerhalRepositoryImpl(ref.watch(terhalRemoteDataSourceProvider));
});
