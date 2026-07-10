import 'package:flutter_bloc/flutter_bloc.dart';

/// Drop-in guard against the "Cannot emit new states after calling close"
/// crash. Mix into any [Cubit] with a `with SafeEmit<...>` clause (the generic
/// must match the cubit's state type) and every [emit] becomes a silent no-op
/// once the cubit is closed, instead of throwing.
///
/// The crash happens when an async method `await`s work and then `emit`s
/// after the owning screen was disposed (the cubit closed mid-`await`). This
/// overrides [emit] to skip when [isClosed], so no call site needs its own
/// `if (isClosed) return;` guard and future cubits are covered by default.
///
/// State-safety ONLY: on the normal (open) path this is a plain passthrough
/// to `super.emit`, so behaviour is unchanged — a closed cubit's emit is
/// simply dropped, with no other side effect.
///
/// Note: this covers [Cubit]s. [Bloc] event handlers emit through a
/// handler-local `Emitter` (guard with `if (emit.isDone) return;`), which a
/// mixin cannot intercept.
mixin SafeEmit<S> on Cubit<S> {
  @override
  void emit(S state) {
    if (isClosed) return;
    super.emit(state);
  }
}
