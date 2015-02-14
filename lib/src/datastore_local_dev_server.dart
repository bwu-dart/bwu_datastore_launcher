library test.launch_datastore_local_dev_server;

import 'dart:async' show Future, Stream, StreamController;
import 'dart:io' as io;
import 'package:path/path.dart' as path;
import 'dart:convert' show UTF8;

// /home/zoechi/google_cloud_datastore_dev_server/gcd-v1beta2-rev1-2.1.1/gcd.sh datastore start
class DatastoreLocalDevServer {
  static const consistencyDefault = 0.9;
  //static const environmentDefault = const <String, String>{'DATASTORE_HOST'}

  /// The directory to use for the datastore data.
  /// This is required by gcd even when `--store_to_disk=false`
  final String datastoreDirectory;
  /// The path to the local dev server start script
  String _exePath;
  String get exePath => _exePath;
  /// The working directory to pass to [io.Process.start]
  final String workingDirectory;
  /// Environment variables to pass to [io.Process.start]
  Map<String, String> environment;
  //final String datasetId;

  String _host;
  String get host => _host;

  int _port;
  int get port => _port;

  io.Process _process;
  int _exitCode;
  int get exitCode => _exitCode;

  StreamController<int> _exitController = new StreamController<int>();
  Stream<int> _exitStream;
  Stream<int> get onExit => _exitStream;

  DatastoreLocalDevServer(this.datastoreDirectory,
      {String exePath, this.workingDirectory, this.environment}) {
    assert(datastoreDirectory != null);
    _exitStream = _exitController.stream.asBroadcastStream();

    if (exePath != null) {
      _exePath = exePath;
    } else {
      _exePath = path.join(io.Platform.environment['HOME'],
          'google_cloud_datastore_dev_server/gcd-v1beta2-rev1-2.1.1/gcd.sh');
    }
  }

  /// Initialize the [datastoreDirectory].
  Future<bool> create(String datasetId, {deleteExisting: false}) async {
    if (deleteExisting) {
      final datastoreDir = new io.Directory(path.join(workingDirectory == null
          ? ''
          : workingDirectory, datastoreDirectory));
      await datastoreDir.exists().then((exists) {
        if (exists) {
          print('Delete existing: ${datastoreDir.absolute.path}');
          return datastoreDir.delete(recursive: true);
        }
      });
    }

    if (_process != null) {
      throw 'Server is already running. Kill it first or create a new DatastoreLocalDevServer instance.';
    } else {
      List<String> arguments = <String>['create'];

      if (datasetId != null) {
        arguments.add('--dataset_id=${datasetId}');
      }

      arguments.add(datastoreDirectory);

      print('Working directory: ${workingDirectory}');
      print('Start: ${exePath} ${arguments.join(' ')}');
      _process = await io.Process.start(exePath, arguments,
          workingDirectory: workingDirectory, environment: environment);
      _process.stdout.listen((stdOut) =>
          io.stdout.add(stdOut));
      _process.stderr.listen((stdErr) => io.stderr
          .add(stdErr));
      _process.exitCode.then((exitCode) {
        _process = null;
        _exitCode = exitCode;
        print('\nexit ${_exitCode}');
        _exitController.add(exitCode);
      });
    }
    return true;
  }

  /// Launch the local dev server. The [datastoreDirectory] needs to exist (can
  /// be created with [create].
  Future start({int port: 0, host: InternetAddress.anyIpV4,
      bool isTesting: false, double consistency: consistencyDefault,
      doStoreOnDisk, bool doAutoGenerateIndexes, allowRemoteShutdown}) async {
    assert(port != null);
    assert(host != null);
    assert(consistency != null && consistency >= 0.0 && consistency <= 1.0);

    if (_process != null) {
      throw 'Server is already running. Kill it first or create a new DatastoreLocalDevServer instance.';
    } else {
      List<String> arguments = <String>['start'];
      if (port == 0) {
        _port = await getNextFreeIpPort();
        arguments.add('--port=${_port}');
      } else {
        _port = port;
        arguments.add('--port=${port}');
      }

      _host = getHost(host);
      arguments.add('--host=${getHost(_host)}');
      if (isTesting) {
        arguments.add('--testing');
      }
      if (consistency != consistencyDefault) {
        arguments.add('--consistency=${consistencyDefault}');
      }
      if (doStoreOnDisk != null) {
        arguments.add('--store_on_disk=${doStoreOnDisk}');
      }
      if (doAutoGenerateIndexes != null) {
        arguments.add('--auto_generate_indexes=${doAutoGenerateIndexes}');
      }
      if (allowRemoteShutdown == true) {
        arguments.add('--allow_remote_shutdown');
      }
      arguments.add(datastoreDirectory);

      print('Working directory: ${workingDirectory}');
      print('Start: ${exePath} ${arguments.join(' ')}');
      return io.Process
          .start(exePath, arguments,
              workingDirectory: workingDirectory, environment: environment)
          .then((process) {
        _process = process;
        _process
          ..stdout.listen(
              io.stdout.add) //print('stdout: ${UTF8.decoder.convert(stdOut)}'))
          ..stderr.listen(
              io.stdout.add) // print('stderr: ${UTF8.decoder.convert(stdErr)}'))
          ..exitCode.then((exitCode) {
            _process = null;
            _exitCode = exitCode;
            print('\nexit ${_exitCode}');
            _exitController.add(exitCode);
          });
        return true;
      });
    }
    return false;
  }

  /// Doesn't work as expected because of http://dartbug.com/3637
  /// Child processes are not killed
  Future<bool> kill(
      [io.ProcessSignal signal = io.ProcessSignal.SIGTERM]) async {
    if (_process == null) {
      return false;
    } else {
      print('kill ${_process.pid}: ${signal}');
      return _process.kill(signal);
    }
  }

  Future<bool> remoteShutdown() {
    return new io.HttpClient()
        .post(host, port, '/_ah/admin/quit')
        .then((request) =>
            request.close().catchError((e) => false).then((_) => true));
  }

  static String getHost(address) {
    if (address is InternetAddress) {
      switch (address) {
        case InternetAddress.loopbackIpV4:
          return io.InternetAddress.LOOPBACK_IP_V4.address;
        case InternetAddress.loopbackIpV6:
          return io.InternetAddress.LOOPBACK_IP_V6.address;
        case InternetAddress.anyIpV4:
          return io.InternetAddress.ANY_IP_V4.address;
        case InternetAddress.anyIpV6:
          return io.InternetAddress.ANY_IP_V6.address;
      }
    }
    return address;
  }

  static Future<int> getNextFreeIpPort(
      {host: InternetAddress.loopbackIpV4}) async {
    return io.ServerSocket.bind(getHost(host), 0).then((socket) {
      final port = socket.port;
      socket.close();
      return port;
    });
  }
}

enum InternetAddress { loopbackIpV4, loopbackIpV6, anyIpV4, anyIpV6, }
