import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';
import 'auth_api.dart';
import 'backup_api.dart';
import 'product_image_api.dart';
import 'sales_api.dart';
import 'secure_token_store.dart';
import 'sync_api.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final secureTokenStoreProvider = Provider<SecureTokenStore>(
  (ref) => SecureTokenStore(ref.watch(secureStorageProvider)),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(store: ref.watch(secureTokenStoreProvider)),
);

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));

final backupApiProvider = Provider<BackupApi>((ref) => BackupApi(ref.watch(apiClientProvider)));

final syncApiProvider = Provider<SyncApi>((ref) => SyncApi(ref.watch(apiClientProvider)));

final salesApiProvider = Provider<SalesApi>((ref) => SalesApi(ref.watch(apiClientProvider)));

final productImageApiProvider = Provider<ProductImageApi>(
  (ref) => ProductImageApi(ref.watch(apiClientProvider)),
);
