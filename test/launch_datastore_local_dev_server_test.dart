library bwu_datastore_launcher.test.launch_datastore_local_dev_server;

import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';
import 'package:bwu_datastore_launcher/bwu_datastore_launcher.dart';
import 'package:bwu_utils_server/package/package.dart';

main() {
  group('launch Datastore Local Dev Server', () {
    test('start and remoteSuthdown', () {
      var exitCalled = expectAsync(() {});

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
    });

    test('start and remoteSuthdown without delay should fail', () {
      var exitCalled = expectAsync(() {});

      // Create an instance of the server launcher.
      final server = new DatastoreLocalDevServer('connect',
          workingDirectory: path.join(
              packageRoot().absolute.path, 'test/tmp_data'),
          // `gcd` uses the `JAVA` environment variable to find the Java
          // executable. We make it to point to Java 7 because `gcd` has issues
          // with Java 8.
          environment: <String, String>{
        'JAVA': '/usr/lib/jvm/java-7-openjdk-amd64/bin/java'
      },
          minUpTimeBeforeShutdown: new Duration(seconds: 0));

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
                .then((success) => expect(success, isFalse))
                .then((_) {
              server.minUpTimeBeforeShutdown = new Duration(seconds: 3);
              return server
                  .remoteShutdown()
                  .then((success) => expect(success, isTrue));
            });
          });
        });
      });
    });
  });
}
