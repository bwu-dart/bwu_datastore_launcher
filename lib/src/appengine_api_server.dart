import 'dart:async' show Future;
import 'dart:io' as io;
import 'package:path/path.dart' as path;
import 'package:bwu_utils/bwu_utils_server.dart' show getFreeIpPort;
import 'package:logging/logging.dart' show Logger, Level;
import 'server.dart' show Server;

final _log = new Logger('bwu_datastore_launcher.appengine_api_server');


/// Wraps the AppEngine API
class AppEngineApiServer extends Server {
  /// Server executable path relative from the SDK root.
  static const String exePathFromSdkRootPath =
      'platform/google_appengine/api_server.py';

  final String gaeLongAppId;
  final String gaeModuleName;
  final String gaeModuleVersion;
  final String gaePartition;
  final bool highReplication;

  final bool trusted;
  final String appidentityEmailAddress;
  final String appidentityPrivateKeyPath;
  final String applicationRoot;
  final String applicationHost;
  int _applicationPort;

  int get applicationPort => _applicationPort;
  final String blobstorePath;
  final AutoIdPolicy autoIdPolicy;
  final bool useSqLite;
  final bool requireIndexes;
  final bool clearDatastore;
  final String logsPath;
  final bool enableSendmail;
  final dynamic smtpHost;
  final String smtpUser;
  final String showMailBody;
  final bool smtpAllowTls;
  final String prospectiveSearchPath;
  final bool clearProspectiveSearch;
  final bool enableTaskRunning;
  final int taskRetrySeconds;
  final String userLoginUrl;
  final String userLogoutUrl;

  /// Create a new instance with a path to [datastoreDirectory] where to create
  /// the data files, an application ID [gaeLongAppId] and [workingDirectory]
  /// if a different than the current one should be used.
  AppEngineApiServer(String datastoreDirectory, this.gaeLongAppId,
      {String workingDirectory,
      Map<String, String> environment,
      String cloudSdkRootPath,
      Duration startupDelay,
      this.gaeModuleName: 'default',
      this.gaeModuleVersion: 'version',
      this.gaePartition: 'dev',
      this.highReplication: true,
      this.trusted,
      this.appidentityEmailAddress,
      this.appidentityPrivateKeyPath,
      this.applicationRoot,
      this.applicationHost,
      int applicationPort,
      this.blobstorePath,
      this.autoIdPolicy,
      this.useSqLite,
      this.requireIndexes,
      this.clearDatastore,
      this.logsPath,
      this.enableSendmail,
      this.smtpHost,
      this.smtpUser,
      this.showMailBody,
      this.smtpAllowTls,
      this.prospectiveSearchPath,
      this.clearProspectiveSearch,
      this.enableTaskRunning,
      this.taskRetrySeconds,
      this.userLoginUrl,
      this.userLogoutUrl})
      : super(datastoreDirectory,
            workingDirectory: workingDirectory,
            environment: environment,
            startupDelay: startupDelay) {
    assert(gaeLongAppId != null && gaeLongAppId.isNotEmpty);
    assert(gaeModuleName != null && gaeModuleName.isNotEmpty);
    assert(gaeModuleVersion != null && gaeModuleVersion.isNotEmpty);
    assert(gaePartition != null && gaePartition.isNotEmpty);

    if (cloudSdkRootPath == null) {
      cloudSdkRootPath = '${io.Platform.environment['HOME']}/google-cloud-sdk/';
    }
    exePath = path.join(cloudSdkRootPath, exePathFromSdkRootPath);
    _applicationPort = applicationPort;
    if (startupDelay == null) {
      this.startupDelay = new Duration(seconds: 2);
    }
  }

  /// Launch the server instance.
  Future start({int apiPort: 0, dynamic host}) async {
    assert(apiPort != null);

    if (host == null) {
      host = io.InternetAddress.ANY_IP_V4;
    } else {
      host = new io.InternetAddress(host);
    }

    List<String> arguments = <String>[];
    arguments.add('-A ${gaePartition}~${gaeLongAppId}');
    if (apiPort == 0) {
      apiPort = await getFreeIpPort();
    }
    port = apiPort;
    arguments.add('--api_port=${port}');

    if (highReplication == true) {
      arguments.add('--high_replication');
    }
    if (trusted == true) {
      arguments.add('--trusted');
    }
    if (appidentityEmailAddress != null && appidentityEmailAddress.isNotEmpty) {
      arguments.add('--appidentity_email_address=${appidentityEmailAddress}');
    }
    if (appidentityPrivateKeyPath != null &&
        appidentityPrivateKeyPath.isNotEmpty) {
      arguments
          .add('--appidentity_private_key_path=${appidentityPrivateKeyPath}');
    }
    if (applicationRoot != null && applicationRoot.isNotEmpty) {
      arguments.add('--application_root=${applicationRoot}');
    }
    if (applicationHost != null && applicationHost.isNotEmpty) {
      arguments.add('--application_host=${applicationHost}');
    }
    if (_applicationPort != null) {
      if (_applicationPort == 0) {
        _applicationPort = await getFreeIpPort();
      }
      arguments.add('--application_port=${_applicationPort}');
    }
    if (blobstorePath != null && blobstorePath.isNotEmpty) {
      arguments.add('--blobstore_path=${blobstorePath}');
    }
    if (datastoreDirectory != null && datastoreDirectory.isNotEmpty) {
      arguments.add('--datastore_path=${datastoreDirectory}');
    }
    if (autoIdPolicy != null) {
      arguments.add('--auto_id_policy=${autoIdPolicy}');
    }
    if (useSqLite == true) {
      arguments.add('--use_sqlite');
    }
    if (requireIndexes == true) {
      arguments.add('--require_indexes');
    }
    if (clearDatastore == true) {
      arguments.add('--clear_datastore');
    }
    if (logsPath != null && logsPath.isNotEmpty) {
      arguments.add('--logs_path=${logsPath}');
    }
    if (enableSendmail == true) {
      arguments.add('--enable_sendmail');
    }
    if (smtpHost != null) {
      // TODO convert enum values (loopbackV4, ...)
      arguments.add('--smtp_host=${smtpHost}');
    }
    if (smtpUser != null && smtpUser.isNotEmpty) {
      arguments.add('--smtp_user=${smtpUser}');
    }
    if (showMailBody == true) {
      arguments.add('--show_mail_body');
    }
    if (smtpAllowTls == true) {
      arguments.add('--smtp_allow_tls');
    }
    if (prospectiveSearchPath != null && prospectiveSearchPath.isNotEmpty) {
      arguments.add('--prospective_search_path=${prospectiveSearchPath}');
    }
    if (clearProspectiveSearch == true) {
      arguments.add('--clear_prospective_search');
    }
    if (enableTaskRunning == true) {
      arguments.add('--enable_task_running');
    }
    if (taskRetrySeconds != null) {
      arguments.add('--task_retry_seconds=${taskRetrySeconds}');
    }
    if (userLoginUrl != null && userLoginUrl.isNotEmpty) {
      arguments.add('--user_login_url=${userLoginUrl}');
    }
    if (userLogoutUrl != null && userLogoutUrl.isNotEmpty) {
      arguments.add('--user_logout_url=${userLogoutUrl}');
    }

    return startProcess(arguments).then((success) {
      final upTime = new DateTime.now().difference(startTime);
      if (success && startupDelay != null && upTime < startupDelay) {
        _log.finer('Delay return from start: ${startupDelay - upTime}');
        return new Future<bool>.delayed(startupDelay - upTime, () => success);
      }
      return new Future<bool>.value(success);
    });
  }
}

/// Possible values for auto-ID policy;
enum AutoIdPolicy {
  /// use ascending numbers
  sequential,

  /// TODO(zoechi)
  scattered
}
