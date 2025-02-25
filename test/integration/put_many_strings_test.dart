import 'package:test/test.dart';

import '../tests/frames.dart';
import '../util/is_browser.dart';
import 'integration.dart';

Future _performTest(bool lazy) async {
  var repeat = isBrowser ? 20 : 1000;
  var box = await openBox(lazy);
  for (var i = 0; i < repeat; i++) {
    for (var frame in valueTestFrames) {
      await box.put('${frame.key}n$i', frame.value);
    }
  }

  box = await reopenBox(box);
  for (var i = 0; i < repeat; i++) {
    for (var frame in valueTestFrames) {
      expect(await getFromBox(box, '${frame.key}n$i'), frame.value);
    }
  }
  await box.close();
}

void main() {
  group('put many strings', () {
    test('normal box', () => _performTest(false));

    test('lazy box', () => _performTest(true));
  }, timeout: longTimeout);
}
