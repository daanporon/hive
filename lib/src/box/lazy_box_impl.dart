// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/box_base_impl.dart';
import 'package:hive/src/hive_impl.dart';

class LazyBoxImpl<E> extends BoxBaseImpl<E> implements LazyBox<E> {
  LazyBoxImpl(
    HiveImpl hive,
    String name,
    KeyComparator keyComparator,
    CompactionStrategy compactionStrategy,
    StorageBackend backend,
  ) : super(hive, name, keyComparator, compactionStrategy, backend);

  @override
  final bool lazy = true;

  @override
  Future<E> get(dynamic key, {E defaultValue}) async {
    checkOpen();

    var frame = keystore.get(key);

    if (frame != null) {
      var value = await backend.readValue(frame);
      if (value is HiveObject) {
        value.init(key, this);
      }
      return value as E;
    } else {
      return defaultValue;
    }
  }

  @override
  Future<E> getAt(int index) {
    return get(keystore.keyAt(index));
  }

  @override
  Future<void> putAll(Map<dynamic, dynamic> kvPairs) async {
    checkOpen();

    var frames = <Frame>[];
    for (var key in kvPairs.keys) {
      frames.add(Frame(key, kvPairs[key]));
      if (key is int) {
        keystore.updateAutoIncrement(key);
      }
    }

    if (frames.isEmpty) return;
    await backend.writeFrames(frames);

    for (var frame in frames) {
      if (frame.value is HiveObject) {
        (frame.value as HiveObject).init(frame.key, this);
      }
      keystore.insert(frame.toLazy());
    }

    await performCompactionIfNeeded();
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    checkOpen();

    var frames = <Frame>[];
    for (var key in keys) {
      if (keystore.containsKey(key)) {
        frames.add(Frame.deleted(key));
      }
    }

    if (frames.isEmpty) return;
    await backend.writeFrames(frames);

    for (var frame in frames) {
      keystore.insert(frame);
    }

    await performCompactionIfNeeded();
  }
}
