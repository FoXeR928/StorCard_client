import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/local/database_service.dart';
import 'data/remote/admin_api.dart';
import 'data/remote/api_client.dart';
import 'data/remote/sync_api.dart';
import 'data/repositories/card_repository.dart';
import 'data/services/admin_service.dart';
import 'data/services/app_info_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/image_service.dart';
import 'data/services/recipient_directory.dart';
import 'data/services/sharing_service.dart';
import 'data/services/sync_service.dart';
import 'viewmodels/cards_viewmodel.dart';
import 'viewmodels/login_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Читаем версию/описание приложения до первого build.
  await AppInfoService.instance.load();
  await DatabaseService.instance.init();

  final auth = AuthService();
  final apiClient = ApiClient(auth);

  final syncService = SyncService(
    dbService: DatabaseService.instance,
    api: SyncApi(apiClient),
    auth: auth,
  );
  final adminService = AdminService(api: AdminApi(apiClient), auth: auth);
  final sharingService = SharingService(apiClient);
  final imageService = ImageService(apiClient);

  final recipients = RecipientDirectory();
  await recipients.load();

  final repo = CardRepository(DatabaseService.instance);
  await syncService.start();

  runApp(
    MultiProvider(
      providers: [
        // ---- Services (инфраструктура) ----
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider.value(value: syncService),
        ChangeNotifierProvider.value(value: adminService),
        ChangeNotifierProvider.value(value: recipients),
        Provider<ApiClient>.value(value: apiClient),
        Provider<SharingService>.value(value: sharingService),
        Provider<ImageService>.value(value: imageService),

        // ---- ViewModels ----
        ChangeNotifierProvider(create: (_) => CardsViewModel(repo, auth)),
        ChangeNotifierProvider(
          create: (_) => LoginViewModel(auth: auth, admin: adminService),
        ),
      ],
      child: const DiscountCardsApp(),
    ),
  );
}
