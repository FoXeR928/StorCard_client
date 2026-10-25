import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/local/database_service.dart';
import 'data/remote/admin_api.dart';
import 'data/remote/api_client.dart';
import 'data/remote/card_api.dart';
import 'data/remote/public_api.dart';
import 'data/remote/user_api.dart';
import 'data/services/card_repository.dart';
import 'data/services/admin_service.dart';
import 'data/services/app_info_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/image_service.dart';
import 'data/services/recipient_directory.dart';
import 'data/services/display_settings.dart';
import 'data/services/sharing_service.dart';
import 'data/services/sync_service.dart';
import 'viewmodels/cards_viewmodel.dart';
import 'viewmodels/login_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppInfoService.instance.load();
  await DatabaseService.instance.init();

  final auth = AuthService();
  final apiClient = ApiClient(auth);

  // 1. Создаем все API-клиенты
  final adminApi = AdminApi(apiClient);
  final userApi = UserApi(apiClient);
  final publicApi = PublicApi(apiClient);
  final cardApi = CardApi(apiClient);

  // 2. Передаем их в сервисы
  final syncService = SyncService(
    dbService: DatabaseService.instance,
    api: cardApi,
    auth: auth,
  );
  final adminService = AdminService(
    adminApi: adminApi,
    userApi: userApi,
    publicApi: publicApi,
    auth: auth,
  );
  final sharingService = SharingService(cardApi);
  final imageService = ImageService(cardApi);

  final recipients = RecipientDirectory();
  await recipients.load();

  final displaySettings = DisplaySettings();
  await displaySettings.load();

  final repo = CardRepository(DatabaseService.instance);
  await syncService.start();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: syncService),
        ChangeNotifierProvider.value(value: adminService),
        ChangeNotifierProvider.value(value: recipients),
        ChangeNotifierProvider.value(value: displaySettings),
        ChangeNotifierProvider(
          create: (_) =>
              CardsViewModel(repo, auth, imageService, apiClient, syncService),
        ),
        Provider<ApiClient>.value(value: apiClient),
        Provider<SharingService>.value(value: sharingService),
        Provider<ImageService>.value(value: imageService),

        ChangeNotifierProvider(
          create: (_) => LoginViewModel(auth: auth, admin: adminService),
        ),
      ],
      child: const DiscountCardsApp(),
    ),
  );
}
