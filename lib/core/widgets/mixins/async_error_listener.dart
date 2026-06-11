import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar;

/// Contract for controllers that expose a transient error message to the
/// UI. Pages consume this via [AsyncErrorListenerMixin], which auto-shows a
/// [SnackBar] and clears the error so the next failure can fire again.
abstract interface class AsyncErrorController implements Listenable {
  /// Latest user-facing error message, or `null` when there is none.
  /// Implementations should reset this to `null` after the message has
  /// been surfaced once (or rely on [clearError]).
  String? get errorMessage;

  /// Resets [errorMessage] to `null` and notifies listeners. No-op when
  /// the controller is already in a clean state.
  void clearError();
}

/// Mixin that wires the standard error-SnackBar pattern repeated across
/// every async page in the app:
///
///   1. Listen to a controller that implements [AsyncErrorController].
///   2. When `errorMessage != null`, surface it as a [SnackBar] and call
///      [AsyncErrorController.clearError] so the next failure can fire.
///   3. Tear down the subscription in [dispose].
///
/// Supports controllers that swap mid-lifecycle (e.g. wizard pages that
/// look up the controller from an [InheritedNotifier] scope at every
/// dependency change): calling [bindAsyncErrorListener] with a new
/// instance auto-detaches the previous one.
mixin AsyncErrorListenerMixin<W extends StatefulWidget> on State<W> {
  AsyncErrorController? _boundAsyncController;

  /// Attaches the SnackBar listener to [controller]. Idempotent — passing
  /// the already-bound controller is a no-op. Passing a new controller
  /// detaches the previous one first.
  void bindAsyncErrorListener(AsyncErrorController controller) {
    if (identical(_boundAsyncController, controller)) return;
    _boundAsyncController?.removeListener(_handleAsyncError);
    _boundAsyncController = controller;
    controller.addListener(_handleAsyncError);
  }

  void _handleAsyncError() {
    final AsyncErrorController? controller = _boundAsyncController;
    if (controller == null) return;
    final String? message = controller.errorMessage;
    if (message == null || !mounted) return;
    controller.clearError();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _boundAsyncController?.removeListener(_handleAsyncError);
    _boundAsyncController = null;
    super.dispose();
  }
}
