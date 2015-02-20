library bwu_datastore_launcher.test.launch_app_engine_api_server;

import 'dart:async' show Future;
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'package:bwu_datastore_launcher/bwu_datastore_launcher.dart';
import 'package:bwu_utils_server/package/package.dart';

main() {
  group('launch AppEngine API Server', () {
    test('start and remoteSuthdown', () {
      var exitCalled = expectAsync(() {});

      // Create an instance of the server launcher.
      final server = new AppEngineApiServer(path.join(
              packageRoot().absolute.path,
              'test/tmp_data/appengine_api_server'), 'test-app',
          clearDatastore: true);

      // launch the Gcloud Datastore Local Development Server
      return server.start().then((success) {
        expect(success, isTrue);

        server.onExit.first.then((code) {
          expect(code, equals(-15));
          exitCalled();
        });

        return new Future.delayed(new Duration(seconds: 2), () => server.kill())
            .then((success) => expect(success, isTrue));
      });
    });
  });
}
