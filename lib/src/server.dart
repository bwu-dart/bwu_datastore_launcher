part of bwu_datastore_launcher;

abstract class Server {
  /// The working directory to passed to [io.Process.start]
  String workingDirectory;
  /// Environment variables to passed to [io.Process.start]
  Map<String, String> environment;

  String _exePath;
  /// The path to the Gcloud SDK root directory
  String get exePath => _exePath;

  io.InternetAddress _host;
  io.InternetAddress get host => _host;

  int _port;
  int get port => _port;

  /// The directory to use for the datastore data.
  /// This is required by gcd even when `--store_to_disk=false`
  final String datastoreDirectory;

  io.Process _process;

  bool get isRunning => _process != null;

  int _exitCode;
  int get exitCode => _exitCode;

  // Wait at least [startupDelay] time before [start] returns to ensure the
  // server is up and ready.
  Duration startupDelay;

  DateTime _startTime;
  DateTime get startTime => _startTime;

  /// Notify when the launched command exits.
  StreamController<int> _exitController = new StreamController<int>();
  Stream<int> _exitStream;
  Stream<int> get onExit => _exitStream;

  Server(this.datastoreDirectory,
      {this.workingDirectory, this.environment, this.startupDelay}) {
    _exitStream = _exitController.stream.asBroadcastStream();
    if (workingDirectory == null) {
      workingDirectory = io.Directory.current.path;
    }
  }

  Future<bool> shutdown() {
    throw '"shutdown" is not implemented';
  }

  Future<bool> kill(
      [io.ProcessSignal signal = io.ProcessSignal.SIGTERM]) async {
    if (_process == null) {
      return false;
    } else {
      _log.finer('kill ${_process.pid}: ${signal}');
      return _process.kill(signal);
    }
  }

  Future<bool> startProcess(List<String> arguments) async {
    if (_process != null) {
      throw 'Server is already running. Kill it first or create a new AppengineApiServer instance.';
    } else {
      _log.finer('Working directory: ${workingDirectory}');
      _log.finer('Start: ${exePath} ${arguments.join(' ')}');
      return io.Process
          .start(exePath, arguments,
              workingDirectory: workingDirectory, environment: environment)
          .then((process) {
        _startTime = new DateTime.now();
        _process = process;
        _process
          ..stdout.listen((stdOut) => _log.finer(UTF8.decoder.convert(stdOut)))
          ..stderr.listen((stdErr) {
            final text = UTF8.decoder.convert(stdErr);
            if (text.startsWith('WARN: ')) {
              _log.warning(text);
            } else if (text.startsWith('ERROR: ')) {
              _log.severe(text);
            } else {
              _log.finer(text);
            }
          })
          ..exitCode.then((exitCode) {
            _process = null;
            _exitCode = exitCode;
            _log.finer('\nexit ${_exitCode}');
            _exitController.add(exitCode);
          });
        return true;
      });
    }
    return false;
  }
}
