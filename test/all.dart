library bwu_datastore_launcher.test.all;

import 'launch_appengine_api_server_test.dart' as lnch_ae;
import 'launch_datastore_local_dev_server_test.dart' as lnch_lds;

void main() {
  lnch_ae.main();
  lnch_lds.main();
}
