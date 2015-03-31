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

@Task()
void init(GrinderContext context) => defaultInit(context);

@Task()
void clean(GrinderContext context) => defaultClean(context);

/// analyze - Analyzer check excluding tests
@Task()
@Depends(init)
void analyze(GrinderContext context) {
  analyzerTask(files: [], directories: ['lib', 'tool', 'test']);
}

/// tests - Run all tests
@Task()
@Depends(init)
void test(GrinderContext context) {
  Tests.runCliTests();
}

/// check - thorough pre-publish check
@Task()
@Depends(init, checkFormat, lint, test)
void check(GrinderContext context) {}

/// check-format - check all for formatting issues
@Task()
@Depends(init)
void checkFormat(GrinderContext context) {
  checkFormatTask(['.']);
}

/// format-all - fix all formatting issues
@Task()
@Depends(init)
void formatAll(GrinderContext context) {
  checkFormatTask(['.']);
}

/// lint - run linter on all files
@Task()
@Depends(init)
void lint(GrinderContext context) {
  linterTask('tool/lintcfg.yaml');
}
