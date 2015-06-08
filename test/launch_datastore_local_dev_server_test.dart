@TestOn('vm')
library bwu_datastore_launcher.test.launch_datastore_local_dev_server;

import 'package:bwu_utils_dev/testing_server.dart';

import 'package:path/path.dart' as path;
import 'package:bwu_datastore_launcher/bwu_datastore_launcher.dart';
import 'package:bwu_utils/bwu_utils_server.dart' as srv_utils;
import 'package:quiver_log/log.dart';

final _log =
    new Logger('bwu_datastore_launcher.test.launch_datastore_local_dev_server');

main() {
  Logger.root.level = Level.FINEST;
  var appender = new PrintAppender(BASIC_LOG_FORMATTER);
  appender.attachLogger(Logger.root);

  group('launch Datastore Local Dev Server', () {
    test('start and remoteSuthdown', () => stackTrace(_log, () {
      var exitCalled = expectAsync(() {});

      // Create an instance of the server launcher.
      final server = new DatastoreLocalDevServer('connect',
          workingDirectory: path.join(
              srv_utils.packageRoot().absolute.path, 'test/.tmp_data'),
          // `gcd` uses the `JAVA` environment variable to find the Java
          // executable. We make it to point to Java 7 because `gcd` has issues
          // with Java 8.
          environment: <String, String>{
        'JAVA': '/usr/lib/jvm/java-7-openjdk-amd64/bin/java'
      });

      // create the datastore directory
      return server.create('test', deleteExisting: true).then((success) {
        expect(success, isTrue);

        // when done launch the Gcloud Datastore Local Development Server
        return server.onExit.first.then((code) {
          return server
              .start(allowRemoteShutdown: true, doStoreOnDisk: false)
              .then((success) {
            expect(success, isTrue);

            server.onExit.first.then((code) {
              expect(code, equals(0));
              exitCalled();
            });

            return server
                .remoteShutdown()
                .then((success) => expect(success, isTrue));
          });
        });
      });
    }));

    test('start and remoteSuthdown without delay should fail', () => stackTrace(
        _log, () {
      // set up
      var exitCalled = expectAsync(() {});

      // Create an instance of the server launcher.
      final server = new DatastoreLocalDevServer('connect',
          workingDirectory: path.join(
              srv_utils.packageRoot().absolute.path, 'test/.tmp_data'),
          // `gcd` uses the `JAVA` environment variable to find the Java
          // executable. We make it to point to Java 7 because `gcd` has issues
          // with Java 8.
          environment: <String, String>{
        'JAVA': '/usr/lib/jvm/java-7-openjdk-amd64/bin/java'
      },
          startupDelay: new Duration(seconds: 0));

      // exercise

      // create the datastore directory
      return server.create('test', deleteExisting: true).then((success) {
        expect(success, isTrue);

        // when done launch the Gcloud Datastore Local Development Server
        return server.onExit.first.then((code) {
          return server
              .start(allowRemoteShutdown: true, doStoreOnDisk: false)
              .then((success) {

            // verify
            expect(success, isTrue);

            server.onExit.first.then((code) {
              expect(code, equals(0));
              exitCalled();
            });

            // tear down
            return server
                .remoteShutdown()
                .then((success) => expect(success, isFalse))
                .then((_) {
              final upTime = new DateTime.now().difference(server.startTime);
              final delay = new Duration(seconds: 3) - upTime;
              return new Future.delayed(delay, () => server.remoteShutdown())
                  .then((success) => expect(success, isTrue));
            });
          });
        });
      });
    }));
  });
}
