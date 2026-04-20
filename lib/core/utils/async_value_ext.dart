import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Extension that treats StateError (service not ready) as loading
/// instead of showing an error to the user.
extension AsyncValueX<T> on AsyncValue<T> {
  Widget whenReady({
    required Widget Function() loading,
    required Widget Function(Object error, StackTrace? st) error,
    required Widget Function(T data) data,
  }) {
    return when(
      loading: loading,
      error: (e, st) {
        // StateError means the IPTV service isn't initialized yet — show loading
        if (e is StateError) return loading();
        return error(e, st);
      },
      data: data,
    );
  }
}
