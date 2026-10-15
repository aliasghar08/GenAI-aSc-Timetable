import 'package:flutter/widgets.dart';

/// Custom, lightweight InheritedNotifier-based Provider implementation
/// Completely eliminates the external `package:provider` dependency.
class AscProvider<T extends Listenable> extends InheritedNotifier<T> {
  const AscProvider({
    super.key,
    required T super.notifier,
    required super.child,
  });

  /// Retrieve and subscribe to changes of type [T]
  static T of<T extends Listenable>(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<AscProvider<T>>();
    assert(provider != null, 'No AscProvider<$T> found in widget hierarchy.');
    return provider!.notifier!;
  }
}

/// Extension methods on BuildContext mirroring standard watch/read ergonomics
extension AscBuildContextExtension on BuildContext {
  /// Watch [T] and rebuild the calling widget whenever [T] notifies listeners
  T watch<T extends Listenable>() => AscProvider.of<T>(this);

  /// Read [T] without subscribing to rebuilds
  T read<T extends Listenable>() {
    final element = getElementForInheritedWidgetOfExactType<AscProvider<T>>()?.widget as AscProvider<T>?;
    assert(element != null, 'No AscProvider<$T> found in widget hierarchy.');
    return element!.notifier!;
  }
}
