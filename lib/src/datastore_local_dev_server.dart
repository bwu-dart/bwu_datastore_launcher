part of bwu_datastore_launcher;

class DatastoreLocalDevServer extends Server {
  static const consistencyDefault = 0.9;

  /// The path to the local dev server start script
  String _exePath;
  String get exePath => _exePath;

  DatastoreLocalDevServer(String datastoreDirectory, {String exePath,
      String workingDirectory, Map<String, String> environment})
      : super(datastoreDirectory,
          workingDirectory: workingDirectory, environment: environment) {
    assert(datastoreDirectory != null);

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
      _process.stdout.listen((stdOut) => io.stdout.add(stdOut));
      _process.stderr.listen((stdErr) => io.stderr.add(stdErr));
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

    List<String> arguments = <String>['start'];
    if (port == 0) {
      port = await getNextFreeIpPort();
    }
    _port = port;
    arguments.add('--port=${_port}');

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

    return startProcess(arguments);
  }

  /// Doesn't work as expected because of http://dartbug.com/3637
  /// Child processes are not killed
  @override
  Future<bool> kill(
      [io.ProcessSignal signal = io.ProcessSignal.SIGTERM]) async {
    return super.kill(signal);
  }

  Future<bool> remoteShutdown() {
    return new io.HttpClient()
        .post(host, port, '/_ah/admin/quit')
        .then((request) =>
            request.close().catchError((e) => false).then((_) => true));
  }
}
