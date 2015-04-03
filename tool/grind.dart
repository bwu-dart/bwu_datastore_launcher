library bwu_datastore_launcher.tool.grind;

import 'package:stack_trace/stack_trace.dart' show Chain;
import 'package:grinder/grinder.dart';

import 'package:bwu_utils/grinder.dart';

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
void analyze() {
  PubApplication tuneup = new PubApplication('tuneup');
  tuneup.run(['check']);
}

@Task('Run all tests')
void test() => Tests.runCliTests();

@Task('Run all checks(analyze, check-fromat, lint, test)')
@Depends(analyze, checkFormat, lint, test)
void check() {}

@Task('Check source code formatting')
void checkFormat() => checkFormatTask(['.']);

@Task('Fix source formatting issues')
void formatAll() => formatAllTask(['.']);

@Task('Run lint checks')
void lint() => linterTask('tool/lintcfg.yaml');
