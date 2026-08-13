import 'package:flutter/widgets.dart';

abstract class SingleChildProvider {
  Widget wrap(Widget child);
}

class ChangeNotifierProvider<T extends ChangeNotifier>
    implements SingleChildProvider {
  final T Function(BuildContext)? create;
  final T? value;

  const ChangeNotifierProvider({
    required this.create,
  }) : value = null;

  const ChangeNotifierProvider.value({
    required this.value,
  }) : create = null;

  @override
  Widget wrap(Widget child) {
    if (value != null) {
      return _ChangeNotifierProviderValue<T>(
        notifier: value!,
        child: child,
      );
    }
    return _ChangeNotifierProviderCreate<T>(
      create: create!,
      child: child,
    );
  }
}

class MultiProvider extends StatelessWidget {
  final List<SingleChildProvider> providers;
  final Widget child;

  const MultiProvider({
    super.key,
    required this.providers,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    Widget tree = child;
    for (final provider in providers.reversed) {
      tree = provider.wrap(tree);
    }
    return tree;
  }
}

class Consumer<T extends ChangeNotifier> extends StatelessWidget {
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;

  const Consumer({
    super.key,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final value = context.watch<T>();
    return builder(context, value, child);
  }
}

extension ProviderCompatBuildContextX on BuildContext {
  T read<T extends ChangeNotifier>() {
    final element = getElementForInheritedWidgetOfExactType<
        _ChangeNotifierProviderScope<T>>();
    final scope = element?.widget as _ChangeNotifierProviderScope<T>?;
    assert(scope != null, 'No provider found for type $T.');
    return scope!.notifier!;
  }

  T watch<T extends ChangeNotifier>() {
    final scope =
        dependOnInheritedWidgetOfExactType<_ChangeNotifierProviderScope<T>>();
    assert(scope != null, 'No provider found for type $T.');
    return scope!.notifier!;
  }
}

class _ChangeNotifierProviderCreate<T extends ChangeNotifier>
    extends StatefulWidget {
  final T Function(BuildContext) create;
  final Widget child;

  const _ChangeNotifierProviderCreate({
    required this.create,
    required this.child,
  });

  @override
  State<_ChangeNotifierProviderCreate<T>> createState() =>
      _ChangeNotifierProviderCreateState<T>();
}

class _ChangeNotifierProviderCreateState<T extends ChangeNotifier>
    extends State<_ChangeNotifierProviderCreate<T>> {
  late final T _notifier = widget.create(context);

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ChangeNotifierProviderScope<T>(
      notifier: _notifier,
      child: widget.child,
    );
  }
}

class _ChangeNotifierProviderValue<T extends ChangeNotifier>
    extends StatelessWidget {
  final T notifier;
  final Widget child;

  const _ChangeNotifierProviderValue({
    required this.notifier,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _ChangeNotifierProviderScope<T>(
      notifier: notifier,
      child: child,
    );
  }
}

class _ChangeNotifierProviderScope<T extends ChangeNotifier>
    extends InheritedNotifier<T> {
  const _ChangeNotifierProviderScope({
    required T super.notifier,
    required super.child,
  });
}
