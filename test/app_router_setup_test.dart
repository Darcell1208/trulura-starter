import 'package:flutter/material.dart';
import 'package:trulura/models/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trulura/core/navigation/app_router.dart';
import 'package:trulura/providers/app_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('legacy adult age alone redirects to birthday completion', (tester) async {
    final app = AppProvider();
    app.setCurrentUser(User.fromJson({'id': 'legacy', 'age': 25, 'name': 'Existing member'}));
    final router = AppRouter.createRouter(appProvider: app);
    router.go(AppRoutes.home);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/onboarding/account-age');
    expect(find.text('Your birthday is required to use TruLura.'), findsOneWidget);
    expect(app.currentUser!.name, 'Existing member');
    expect(app.currentUser!.age, 25);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    app.dispose();
  });
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
