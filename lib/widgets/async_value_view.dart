import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../theme/colors.dart';
import 'empty_state.dart';

/// The shared "loading / error+retry / empty / data" shape this app never
/// had before — every screen that talks to mock data today either has no
/// failure path at all, or duplicates its own ad hoc `_loading` flag. Wraps
/// [EmptyState] for both the error and empty cases rather than inventing a
/// new visual, since that widget is already used consistently across 8+
/// screens.
class AsyncValueView<T> extends StatefulWidget {
  final Future<T> Function() loader;
  final Widget Function(BuildContext context, T value) builder;

  /// True when [value] should be treated as "nothing to show" — e.g. an
  /// empty list. Defaults to never-empty (some screens' "data" is never
  /// meaningfully empty, e.g. a single object).
  final bool Function(T value) isEmpty;
  final Widget Function(BuildContext context)? emptyBuilder;

  const AsyncValueView({
    super.key,
    required this.loader,
    required this.builder,
    this.isEmpty = _neverEmpty,
    this.emptyBuilder,
  });

  static bool _neverEmpty(Object? value) => false;

  @override
  State<AsyncValueView<T>> createState() => _AsyncValueViewState<T>();
}

class _AsyncValueViewState<T> extends State<AsyncValueView<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  void _retry() => setState(() {
        _future = widget.loader();
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppColors.blue)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: EmptyState(
                icon: Ionicons.cloud_offline_outline,
                title: "Couldn't load this",
                subtitle: 'Check your connection and try again.',
                buttonLabel: 'Try again',
                onButtonTap: _retry,
              ),
            ),
          );
        }
        final value = snapshot.data as T;
        if (widget.isEmpty(value)) {
          return widget.emptyBuilder?.call(context) ?? const SizedBox.shrink();
        }
        return widget.builder(context, value);
      },
    );
  }
}
