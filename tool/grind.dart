library bwu_datastore_launcher.tool.grind;

export 'package:bwu_utils_dev/grinder/default_tasks.dart' hide main, testWeb;
import 'package:bwu_utils_dev/grinder/default_tasks.dart'
    show grind, testTask, testTaskImpl;

main(List<String> args) {
  testTask = ([_]) => testTaskImpl(['vm']);
  grind(args);
}
