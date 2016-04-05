@TestOn('vm')
library bwu_datastore_launcher.test.launch_datastore_local_dev_server;

import 'dart:async' show Future, Stream;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:bwu_datastore_launcher/bwu_datastore_launcher.dart';
import 'package:bwu_utils/bwu_utils_server.dart' as srv_utils;
import 'package:logging/logging.dart' show Logger, Level;
import 'package:quiver_log/log.dart' show PrintAppender, BASIC_LOG_FORMATTER;

// created the data-dir
// docker run -p 8891:8891/tcp --rm -ti --volumes-from gcloud-config -v /home/zoechi/dart/bwu_datastore_launcher/test/.tmp_data/connect/:/connect zoechi/google_cloud_sdk gcloud beta emulators datastore start --data-dir=/connect

final _log =
    new Logger('bwu_datastore_launcher.test.launch_gcloud_datastore_emulator');

///
void main() {
  Logger.root.level = Level.FINEST;
  var appender = new PrintAppender(BASIC_LOG_FORMATTER);
  appender.attachLogger(Logger.root);

  group('launch Datastore Local Dev Server', () {
    test('start and remoteSuthdown', () {
      var exitCalled = expectAsync(() {});

      final workDir = path.join(
          srv_utils.packageRoot().absolute.path, 'test/.tmp_data/connect/');
      // Create an instance of the server launcher.
      final server = new DockerGCloudDatastoreEmulator(
          exePath: 'docker',
          datastoreDirectory: workDir,
          configVolumeName: 'gcloud-config',
          dockerParameters: 'run --rm'.split(' '));

      return server.start().then((success) {
        expect(success, isTrue);

        server.onExit.first.then((code) {
          expect(code, equals(0));
          exitCalled();
        });

        return server
            .remoteShutdown()
            .then((success) => expect(success, isTrue));
      });
    }, timeout: const Timeout(const Duration(minutes: 1)), skip: false);

    test('start and remoteShutdown without delay should fail', () {
      // set up
      var exitCalled = expectAsync(() {});

      final workDir = path.join(
          srv_utils.packageRoot().absolute.path, 'test/.tmp_data/connect/');

      // Create an instance of the server launcher.
      final server = new DockerGCloudDatastoreEmulator(
          exePath: 'docker',
          datastoreDirectory: workDir,
          configVolumeName: 'gcloud-config',
          dockerParameters: 'run --rm'.split(' '),
          startupDelay: new Duration(seconds: 0));

      // exercise

      return server
          .start(/*allowRemoteShutdown: true,*/ doStoreOnDisk: false)
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
}
