library bwu_datastore_launcher.test.launch_datastore_local_dev_server;

import 'dart:io' as io;
import 'dart:async' show Future;
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'package:bwu_datastore_launcher/bwu_datastore_launcher.dart';
import 'package:bwu_utils_server/package/package.dart';

main() async {
  useVMConfiguration();

  group('launch local dev server', () {

    test('start and remoteSuthdown', () {
      var exitCalled = expectAsync((){});

      // Create an instance of the server launcher.
      final server = new DatastoreLocalDevServer('connect',
          workingDirectory: path.join(
              packageRoot().absolute.path, 'test/tmp_data'),
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
        server.onExit.first.then((code) {
          return server
              .start(allowRemoteShutdown: true, doStoreOnDisk: false)
              .then((success) {
            expect(success, isTrue);

            server.onExit.first.then((code) {
              expect(code, equals(0));
              exitCalled();
            });

            // We need to wait a little until the server is able to receive
            // requests.
            return new Future.delayed(new Duration(seconds: 3),
                // () => server.kill(io.ProcessSignal.SIGTERM))
                // Darts Process kill doesn't kill child processes, therefore we
                // use the `remoteShutdown` feature of the server to not keep
                // unnecessary server processes running.
                () => server.remoteShutdown()).then(
                (success) => expect(success, isTrue));
          });
        });
      });
    });
  });
}
