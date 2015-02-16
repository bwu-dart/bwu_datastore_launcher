library bwu_datastore_launcher.test.launch_app_engine_api_server;

import 'dart:io' as io;
import 'dart:async' show Future;
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'package:bwu_datastore_launcher/bwu_datastore_launcher.dart';

main() async {
  useVMConfiguration();

  group('launch local dev server', () {
    test('start and remoteSuthdown', () {
      var exitCalled = expectAsync(() {});

      // Create an instance of the server launcher.
      final server = new AppEngineApiServer(
          path.join(packageRoot().absolute.path, 'test/tmp_data/appengine_api_server'), 'test-app', clearDatastore: true);

      // launch the Gcloud Datastore Local Development Server
      return server.start().then((success) {
        expect(success, isTrue);

        server.onExit.first.then((code) {
          expect(code, equals(-15));
          exitCalled();
        });

        return new Future.delayed(new Duration(seconds: 2),
                () => server.kill())
            .then((success) => expect(success, isTrue));
      });
    });
  });
}

/// Traverse upwards until `pubspec.yaml` is found and return the directory path.
/// We use paths relative to the package root, therefore we need to know where
/// the package root actually is.
/// This way the tests work when launched from IDE and for example from
/// test_runner.
io.Directory packageRoot([io.Directory startDir]) {
  if (startDir == null) {
    startDir = io.Directory.current;
  }
  final exists = new io.File(path.join(startDir.absolute.path, 'pubspec.yaml'))
      .existsSync();

  if (exists) return startDir;
  if (startDir.parent == startDir) return null;
  return packageRoot(startDir.parent);
}
