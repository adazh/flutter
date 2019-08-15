// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'message.dart';

/// A Flutter Driver command that waits until a given [condition] is satisfied.
class WaitForCondition extends Command {
  /// Creates a command that waits for the given [condition] is met.
  const WaitForCondition(this.condition, {Duration timeout})
      : assert(condition != null),
        super(timeout: timeout);

  /// Deserializes this command from the value generated by [serialize].
  ///
  /// The [json] argument cannot be null.
  WaitForCondition.deserialize(Map<String, String> json)
      : assert(json != null),
        condition = _WaitConditionDecoder.deserialize(json),
        super.deserialize(json);

  /// The condition that this command shall wait for.
  final WaitCondition condition;

  @override
  Map<String, String> serialize() => super.serialize()..addAll(condition.serialize());

  @override
  String get kind => 'waitForCondition';
}

/// A Flutter Driver command that waits until there are no more transient callbacks in the queue.
///
/// This command has been deprecated in favor of [WaitForCondition]. Construct
/// a command that waits until no transient callbacks as follows:
///
/// ```dart
/// WaitForCondition noTransientCallbacks = WaitForCondition(NoTransientCallbacksCondition());
/// ```
@Deprecated('This command has been deprecated in favor of WaitForCondition. '
            'Use WaitForCondition command with NoTransientCallbacksCondition.')
class WaitUntilNoTransientCallbacks extends Command {
  /// Creates a command that waits for there to be no transient callbacks.
  const WaitUntilNoTransientCallbacks({ Duration timeout }) : super(timeout: timeout);

  /// Deserializes this command from the value generated by [serialize].
  WaitUntilNoTransientCallbacks.deserialize(Map<String, String> json)
      : super.deserialize(json);

  @override
  String get kind => 'waitUntilNoTransientCallbacks';
}

/// A Flutter Driver command that waits until the frame is synced.
///
/// This command has been deprecated in favor of [WaitForCondition]. Construct
/// a command that waits until no pending frame as follows:
///
/// ```dart
/// WaitForCondition noPendingFrame = WaitForCondition(NoPendingFrameCondition());
/// ```
@Deprecated('This command has been deprecated in favor of WaitForCondition. '
            'Use WaitForCondition command with NoPendingFrameCondition.')
class WaitUntilNoPendingFrame extends Command {
  /// Creates a command that waits until there's no pending frame scheduled.
  const WaitUntilNoPendingFrame({ Duration timeout }) : super(timeout: timeout);

  /// Deserializes this command from the value generated by [serialize].
  WaitUntilNoPendingFrame.deserialize(Map<String, String> json)
      : super.deserialize(json);

  @override
  String get kind => 'waitUntilNoPendingFrame';
}

/// A Flutter Driver command that waits until the Flutter engine rasterizes the
/// first frame.
///
/// {@template flutter.frame_rasterized_vs_presented}
/// Usually, the time that a frame is rasterized is very close to the time that
/// it gets presented on the display. Specifically, rasterization is the last
/// expensive phase of a frame that's still in Flutter's control.
/// {@endtemplate}
///
/// This command has been deprecated in favor of [WaitForCondition]. Construct
/// a command that waits until no pending frame as follows:
///
/// ```dart
/// WaitForCondition firstFrameRasterized = WaitForCondition(FirstFrameRasterizedCondition());
/// ```
@Deprecated('This command has been deprecated in favor of WaitForCondition. '
            'Use WaitForCondition command with FirstFrameRasterizedCondition.')
class WaitUntilFirstFrameRasterized extends Command {
  /// Creates this command.
  const WaitUntilFirstFrameRasterized({ Duration timeout }) : super(timeout: timeout);

  /// Deserializes this command from the value generated by [serialize].
  WaitUntilFirstFrameRasterized.deserialize(Map<String, String> json)
      : super.deserialize(json);

  @override
  String get kind => 'waitUntilFirstFrameRasterized';
}

/// Base class for a condition that can be waited upon.
abstract class WaitCondition {
  /// Gets the current status of the [condition], executed in the context of the
  /// Flutter app:
  ///
  /// * True, if the condition is satisfied.
  /// * False otherwise.
  ///
  /// The future returned by [wait] will complete when this [condition] is
  /// fulfilled.
  bool get condition;

  /// Returns a future that completes when [condition] turns true.
  Future<void> wait();

  /// Serializes the object to JSON.
  Map<String, String> serialize();
}

/// Thrown to indicate a JSON serialization error.
class SerializationException implements Exception {
  /// Creates a [SerializationException] with an optional error message.
  const SerializationException([this.message]);

  /// The error message, possibly null.
  final String message;

  @override
  String toString() => 'SerializationException($message)';
}

/// A condition that waits until no transient callbacks are scheduled.
class NoTransientCallbacksCondition implements WaitCondition {
  /// Creates a [NoTransientCallbacksCondition] instance.
  const NoTransientCallbacksCondition();

  /// Factory constructor to parse a [NoTransientCallbacksCondition] instance
  /// from the given JSON map.
  ///
  /// The [json] argument cannot be null.
  factory NoTransientCallbacksCondition.deserialize(Map<String, dynamic> json) {
    assert(json != null);
    if (json['conditionName'] != 'NoTransientCallbacksCondition')
      throw SerializationException('Error occurred during deserializing the NoTransientCallbacksCondition JSON string: $json');
    return const NoTransientCallbacksCondition();
  }

  @override
  bool get condition => SchedulerBinding.instance.transientCallbackCount == 0;

  @override
  Future<void> wait() async {
    while (!condition) {
      await SchedulerBinding.instance.endOfFrame;
    }
    assert(condition);
  }

  @override
  Map<String, String> serialize() {
    return <String, String>{
      'conditionName': 'NoTransientCallbacksCondition',
    };
  }
}

/// A condition that waits until no pending frame is scheduled.
class NoPendingFrameCondition implements WaitCondition {
  /// Creates a [NoPendingFrameCondition] instance.
  const NoPendingFrameCondition();

  /// Factory constructor to parse a [NoPendingFrameCondition] instance from the
  /// given JSON map.
  ///
  /// The [json] argument cannot be null.
  factory NoPendingFrameCondition.deserialize(Map<String, dynamic> json) {
    assert(json != null);
    if (json['conditionName'] != 'NoPendingFrameCondition')
      throw SerializationException('Error occurred during deserializing the NoPendingFrameCondition JSON string: $json');
    return const NoPendingFrameCondition();
  }

  @override
  bool get condition => !SchedulerBinding.instance.hasScheduledFrame;

  @override
  Future<void> wait() async {
    while (!condition) {
        await SchedulerBinding.instance.endOfFrame;
    }
    assert(condition);
  }

  @override
  Map<String, String> serialize() {
    return <String, String>{
      'conditionName': 'NoPendingFrameCondition',
    };
  }
}

/// A condition that waits until the Flutter engine has rasterized the first frame.
class FirstFrameRasterizedCondition implements WaitCondition {
  /// Creates a [FirstFrameRasterizedCondition] instance.
  const FirstFrameRasterizedCondition();

  /// Factory constructor to parse a [NoPendingFrameCondition] instance from the
  /// given JSON map.
  ///
  /// The [json] argument cannot be null.
  factory FirstFrameRasterizedCondition.deserialize(Map<String, dynamic> json) {
    assert(json != null);
    if (json['conditionName'] != 'FirstFrameRasterizedCondition')
      throw SerializationException('Error occurred during deserializing the FirstFrameRasterizedCondition JSON string: $json');
    return const FirstFrameRasterizedCondition();
  }

  @override
  bool get condition => WidgetsBinding.instance.firstFrameRasterized;

  @override
  Future<void> wait() async {
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    assert(condition);
  }

  @override
  Map<String, String> serialize() {
    return <String, String>{
      'conditionName': 'FirstFrameRasterizedCondition',
    };
  }
}

/// A combined condition that waits until all the given [conditions] are met.
class CombinedCondition implements WaitCondition {
  /// Creates a [CombinedCondition] instance with the given list of
  /// [conditions].
  ///
  /// The [conditions] argument cannot be null.
  const CombinedCondition(this.conditions)
    : assert(conditions != null);

  /// Factory constructor to parse a [CombinedCondition] instance from the given
  /// JSON map.
  ///
  /// The [jsonMap] argument cannot be null.
  factory CombinedCondition.deserialize(Map<String, dynamic> jsonMap) {
    assert(jsonMap != null);
    if (jsonMap['conditionName'] != 'CombinedCondition')
      throw SerializationException('Error occurred during deserializing the CombinedCondition JSON string: $jsonMap');
    if (jsonMap['conditions'] == null) {
      return const CombinedCondition(<WaitCondition>[]);
    }

    final List<WaitCondition> conditions = <WaitCondition>[];
    for (Map<String, dynamic> condition in json.decode(jsonMap['conditions'])) {
      conditions.add(_WaitConditionDecoder.deserialize(condition));
    }
    return CombinedCondition(conditions);
  }

  /// A list of conditions it waits for.
  final List<WaitCondition> conditions;

  @override
  bool get condition {
    return conditions.every((WaitCondition condition) => condition.condition);
  }

  @override
  Future<void> wait() async {
    while (!condition) {
      for (WaitCondition condition in conditions) {
        assert (condition != null);
        await condition.wait();
      }
    }
    assert(condition);
  }

  @override
  Map<String, String> serialize() {
    final Map<String, String> jsonMap = <String, String>{
      'conditionName': 'CombinedCondition'
    };
    final List<Map<String, String>> jsonConditions = conditions.map(
        (WaitCondition condition) {
          assert(condition != null);
          return condition.serialize();
        }).toList();
    jsonMap['conditions'] = json.encode(jsonConditions);
    return jsonMap;
  }
}

/// A JSON decoder that parses JSON map to a [WaitCondition] or its subclass.
class _WaitConditionDecoder {
  /// Parses a [WaitCondition] or its subclass from the given [json] map.
  ///
  /// The [json] argument cannot be null.
  static WaitCondition deserialize(Map<String, dynamic> json) {
    assert(json != null);
    final String conditionName = json['conditionName'];
    switch (conditionName) {
      case 'NoTransientCallbacksCondition':
        return NoTransientCallbacksCondition.deserialize(json);
      case 'NoPendingFrameCondition':
        return NoPendingFrameCondition.deserialize(json);
      case 'CombinedCondition':
        return CombinedCondition.deserialize(json);
    }
    throw SerializationException('Unsupported wait condition $conditionName in the JSON string $json');
  }
}
