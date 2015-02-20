part of bwu_datastore_launcher;

class DatastoreLocalDevServer extends Server {
  static const consistencyDefault = 0.9;

  /// The path to the local dev server start script
  String _exePath;
  String get exePath => _exePath;

  DatastoreLocalDevServer(String datastoreDirectory, {String exePath,
      String workingDirectory, Map<String, String> environment,
      Duration minUpTimeBeforeShutdown})
      : super(datastoreDirectory,
          workingDirectory: workingDirectory,
          environment: environment,
          minUpTimeBeforeShutdown: minUpTimeBeforeShutdown) {
    assert(datastoreDirectory != null);

    if (exePath != null) {
      _exePath = exePath;
    } else {
      _exePath = path.join(io.Platform.environment['HOME'],
          'google_cloud_datastore_dev_server/gcd-v1beta2-rev1-2.1.1/gcd.sh');
    }
    if (minUpTimeBeforeShutdown == null) {
      this.minUpTimeBeforeShutdown = new Duration(seconds: 3);
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
          _log.finer('Delete existing: ${datastoreDir.absolute.path}');
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
      return startProcess(arguments);
    }
    return true;
  }

  /// Launch the local dev server. The [datastoreDirectory] needs to exist (can
  /// be created with [create].
  Future start({int port: 0, host, bool isTesting: false,
      double consistency: consistencyDefault, doStoreOnDisk,
      bool doAutoGenerateIndexes, allowRemoteShutdown}) async {
    assert(port != null);
    assert(consistency != null && consistency >= 0.0 && consistency <= 1.0);

    if (host == null) {
      this._host = io.InternetAddress.LOOPBACK_IP_V4;
    } else {
      this._host = new io.InternetAddress(host);
    }

    List<String> arguments = <String>['start'];
    if (port == 0) {
      port = await getNextFreeIpPort();
    }
    _port = port;
    arguments.add('--port=${_port}');

    arguments.add('--host=${_host.address}');
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

    return startProcess(arguments);
  }

  /// Doesn't work as expected because of http://dartbug.com/3637
  /// Child processes are not killed
  @override
  Future<bool> kill(
      [io.ProcessSignal signal = io.ProcessSignal.SIGTERM]) async {
    //return super.kill(signal);
    throw 'Use `remoteShutdown()` until http://dartbug.com/3637 is fixed.';
  }

  Future<bool> remoteShutdown() {
    final shutdown = () => new io.HttpClient()
        .post(host.address, port, '/_ah/admin/quit')
        .then((request) => request.close())
        .then((_) => true)
        .catchError((e) {
      _log.severe('"RemoteShutdown" failed: ${e}');
      return false;
    });

    final upTime = new DateTime.now().difference(recentLaunchTime);
    if (minUpTimeBeforeShutdown != null && upTime < minUpTimeBeforeShutdown) {
      _log.finer('Delay remote shutdown: ${minUpTimeBeforeShutdown - upTime}');
      return new Future<bool>.delayed(
          minUpTimeBeforeShutdown - upTime, () => shutdown());
    }
    return shutdown();
  }
}
