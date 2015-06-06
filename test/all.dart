library bwu_datastore_launcher.test.all;

import 'launch_appengine_api_server_test.dart' as laas;
import 'launch_datastore_local_dev_server_test.dart' as ldld;

main() {
  laas.main();
  ldld.main();
}
