library bwu_datastore_launcher.test.launch_app_engine_api_server;

import 'package:bwu_utils_dev/testing_server.dart';

import 'package:path/path.dart' as path;
import 'package:bwu_datastore_launcher/bwu_datastore_launcher.dart';
import 'package:bwu_utils/bwu_utils_server.dart' as srv_utils;

final _log =
    new Logger('bwu_datastore_launcher.test.launch_app_engine_api_server');

main() {
  group('launch AppEngine API Server', () {
    test('start and remoteSuthdown', () => stackTrace(_log, () {
      var exitCalled = expectAsync(() {});

      // Create an instance of the server launcher.
      final server = new AppEngineApiServer(path.join(
              srv_utils.packageRoot().absolute.path,
              'test/.tmp_data/appengine_api_server'), 'test-app',
          clearDatastore: true);

      // launch the Gcloud Datastore Local Development Server
      return server.start().then((success) {
        expect(success, isTrue);

        server.onExit.first.then((code) {
          expect(code, equals(-15));
          exitCalled();
        });

        return server.kill().then((success) => expect(success, isTrue));
      });
    }));
  });
}
