library bwu_datastore_launcher.tool.grind;

import 'package:stack_trace/stack_trace.dart' show Chain;
import 'package:grinder/grinder.dart';

import 'package:bwu_utils_dev/grinder.dart';

const existingSourceDirs = const ['lib', 'test', 'tool'];

void main(List<String> args) {
  Chain.capture(() => _main(args), onError: (error, stack) {
    print(error);
    print(stack.terse);
  });
}

// TODO(zoechi) check if version was incremented
// TODO(zoechi) check if CHANGELOG.md contains version

_main(List<String> args) => grind(args);

@Task('Analyze all dart files')
analyze() => Pub.global.run('tuneup', arguments: ['check']);

@Task('Run all tests')
test() => Pub.run('test');

@Task('Run all checks(analyze, check-fromat, lint, test)')
@Depends(analyze, checkFormat, lint, test)
void check() {}

@Task('Check source code formatting')
void checkFormat() => checkFormatTask(['.']);

@Task('Fix source formatting issues')
void formatAll() => DartFmt.format(existingSourceDirs);

@Task('Run lint checks')
lint() => new PubApp.global('linter')
    .run(['--stats', '-ctool/lintcfg.yaml']..addAll(existingSourceDirs));
