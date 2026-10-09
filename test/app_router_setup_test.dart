import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/providers/app_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('main tabs retain their destinations and account setup is registered once', () {
    final app = AppProvider();
    final router = AppRouter.createRouter(appProvider: app);
    addTearDown(router.dispose);
    addTearDown(app.dispose);
    final routes = router.configuration.routes;
    final shell = routes.whereType<StatefulShellRoute>().single;
    expect(shell.branches.map((branch) => (branch.routes.first as GoRoute).path),
        [AppRoutes.home, AppRoutes.messages, AppRoutes.notifications, AppRoutes.profile]);
    final setup = <GoRoute>[];
    void visit(List<RouteBase> items) {
      for (final route in items) {
        if (route is GoRoute && route.path == '/onboarding/account-age') setup.add(route);
        visit(route.routes);
      }
    }
    visit(routes);
    expect(setup, hasLength(1));
  });
}
