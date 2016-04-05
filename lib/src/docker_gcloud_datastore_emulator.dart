import 'dart:io' as io;
import 'dart:async' show Future;
//import 'package:bwu_utils/bwu_utils_server.dart' show getFreeIpPort;
import 'package:logging/logging.dart' show Logger, Level;
import 'server.dart' show Server;

final _log = new Logger('bwu_datastore_launcher.gcloud_datastore_emulator');

///
class DockerGCloudDatastoreEmulator extends Server {
  ///
  static const double consistencyDefault = 0.9;

  /// The path to the local dev server start script
//  @override
//  String get exePath => super._exePath;

  List<String> dockerParameters;

  /// A config name from `gcloud config list`
  String configName;

  /// A volume created by
  /// `docker run -t -i --name gcloud-config google/cloud-sdk gcloud init`
  /// where `gcloud-config` is the created volume name.
  String configVolumeName;

  /// Create a new instance of a local dev server.
  DockerGCloudDatastoreEmulator(
      {String datastoreDirectory,
      String exePath,
      Map<String, String> environment,
      this.dockerParameters,
      this.configName,
      this.configVolumeName,
      Duration startupDelay})
      : super(datastoreDirectory,
            environment: environment, startupDelay: startupDelay) {
    this.exePath = exePath ?? 'docker';
    if (startupDelay == null) {
      this.startupDelay = new Duration(seconds: 3);
    }
  }

  /// Launch the local dev server.
  //The [datastoreDirectory] needs to exist.
  Future<bool> start(
      {int port: 0,
      //dynamic host,
      //bool isTesting: false,
      List<String> dockerParameters,

      /// A name to select a stored configuration. Available names are returned
      /// by `gcloud config list`.
      double consistency: consistencyDefault,
      bool doStoreOnDisk
//      bool doAutoGenerateIndexes,
      }) async {
    assert(port != null);
    assert(consistency != null && consistency >= 0.0 && consistency <= 1.0);

    List<String> arguments = <String>[];
    if (port == 0) {
      port = 8891;
    }
    this.port = port;
    arguments.add('--host-port=0.0.0.0:${port}');

    List<String> dockerParams =
        this.dockerParameters ?? dockerParameters ?? <String>[];
    dockerParams.insertAll(1, ['-p', '${port}:${port}/tcp']);

    if (configVolumeName != null) {
      dockerParams.insertAll(1, ['--volumes-from', configVolumeName]);
    }

    if (consistency != consistencyDefault) {
      arguments.add('--consistency=${consistencyDefault}');
    }
    if (doStoreOnDisk != null) {
      arguments.add('--store-on-disk=${doStoreOnDisk}');
    }
//    if (doAutoGenerateIndexes != null) {
//      arguments.add('--auto_generate_indexes=${doAutoGenerateIndexes}');
//    }
    if (datastoreDirectory != null) {
      dockerParams.addAll(['-v', '${datastoreDirectory}:/data']);
    }

    if (configName != null) {
      arguments.addAll(['--configuration', configName]);
    }

    dockerParams.addAll([
      'zoechi/google_cloud_sdk',
      'gcloud',
      'beta',
      'emulators',
      'datastore',
      'start',
      '--data-dir',
      '/data'
    ]);

    return startProcess(<String>[]..addAll(dockerParams)..addAll(arguments))
        .then((success) {
      final upTime = new DateTime.now().difference(startTime);
      if (success && startupDelay != null && upTime < startupDelay) {
        _log.finer('Delay return from start: ${startupDelay - upTime}');
        return new Future<bool>.delayed(startupDelay - upTime, () => success);
      }
      return new Future<bool>.value(success);
    });
  }

  /// Doesn't work as expected because of http://dartbug.com/3637
  /// Child processes are not killed
  @override
  Future<bool> kill(
      [io.ProcessSignal signal = io.ProcessSignal.SIGTERM]) async {
    //return super.kill(signal);
    throw 'Use `remoteShutdown()` until http://dartbug.com/3637 is fixed.';
  }

  /// Send a command to the server to shut itself down.
  Future<bool> remoteShutdown() {
    if (!this.isRunning) {
      return new Future.value(false);
    }
    return new io.HttpClient()
        .post(
            io.InternetAddress.LOOPBACK_IP_V6.address, port, '/_ah/admin/quit')
        .then((request) => request.close())
        .then((_) => true)
        .catchError((e) {
      _log.severe('"RemoteShutdown" failed: ${e}');
      return false;
    }) as Future<bool>;
  }
}
