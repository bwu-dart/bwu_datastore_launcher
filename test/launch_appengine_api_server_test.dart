library bwu_datastore_launcher.test.launch_app_engine_api_server;

import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';
import 'package:bwu_datastore_launcher/bwu_datastore_launcher.dart';
import 'package:bwu_utils_server/package/package.dart';

import 'package:logging/logging.dart' show Logger, Level;
import 'package:quiver_log/log.dart' show BASIC_LOG_FORMATTER, PrintAppender;

final _logger =
    new Logger('bwu_datastore_launcher.test.launch_app_engine_api_server');

main() {
  Logger.root.level = Level.INFO;
  var appender = new PrintAppender(BASIC_LOG_FORMATTER);
  appender.attachLogger(Logger.root);

  group('launch AppEngine API Server', () {
    test('start and remoteSuthdown', () {
      var exitCalled = expectAsync(() {});

      // Create an instance of the server launcher.
      final server = new AppEngineApiServer(path.join(
              packageRoot().absolute.path,
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
    });
  });
}
