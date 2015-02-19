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
  int _exitCode;
  int get exitCode => _exitCode;

  /// Notify when the launched command exits.
  StreamController<int> _exitController = new StreamController<int>();
  Stream<int> _exitStream;
  Stream<int> get onExit => _exitStream;

  Server(this.datastoreDirectory, {this.workingDirectory, this.environment}) {
    _exitStream = _exitController.stream.asBroadcastStream();
    if (workingDirectory == null) {
      workingDirectory = io.Directory.current.path;
    }
  }

  Future<bool> kill(
      [io.ProcessSignal signal = io.ProcessSignal.SIGTERM]) async {
    if (_process == null) {
      return false;
    } else {
      print('kill ${_process.pid}: ${signal}');
      return _process.kill(signal);
    }
  }

  Future<bool> startProcess(List<String> arguments) async {
    if (_process != null) {
      throw 'Server is already running. Kill it first or create a new AppengineApiServer instance.';
    } else {
      print('Working directory: ${workingDirectory}');
      print('Start: ${exePath} ${arguments.join(' ')}');
      return io.Process
          .start(exePath, arguments,
              workingDirectory: workingDirectory, environment: environment)
          .then((process) {
        _process = process;
        _process
          ..stdout.listen(io.stdout.add)
          ..stderr.listen(io.stdout.add)
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
}
