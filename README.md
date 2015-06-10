#BWU Datastore Launcher

[![Star this Repo](https://img.shields.io/github/stars/bwu-dart/bwu_datastore_launcher.svg?style=flat)](https://github.com/bwu-dart/bwu_datastore_launcher)
[![Pub Package](https://img.shields.io/pub/v/bwu_datastore_launcher.svg?style=flat)](https://pub.dartlang.org/packages/bwu_datastore_launcher)
[![Build Status](https://travis-ci.org/bwu-dart/bwu_datastore_launcher.svg?branch=master)](https://travis-ci.org/bwu-dart/bwu_datastore_launcher)
[![Coverage Status](https://coveralls.io/repos/bwu-dart/bwu_datastore_launcher/badge.svg?branch=master)](https://coveralls.io/r/bwu-dart/bwu_datastore_launcher)

Simplify starting and stopping local Google Cloud Datastore Local Development
Server(s) or AppEngine API Server(s) from unit tests.

See also:

- https://cloud.google.com/datastore/docs/tools/devserver
- https://cloud.google.com/datastore/docs/tools/
- https://cloud.google.com/sdk/gcloud/

## Usage

### Google Cloud Datastore Local Development Server example

```Dart
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
      var exitCalled = expectAsync((){});

      // Create an instance of the server launcher.
      final server = new DatastoreLocalDevServer('connect',
          workingDirectory: path.join(
              packageRoot().absolute.path, 'test/tmp_data/datastore_local_dev_server'),
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

            return new Future.delayed(new Duration(seconds: 2),
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
```

### AppEngine API Server example

```Dart
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
```
