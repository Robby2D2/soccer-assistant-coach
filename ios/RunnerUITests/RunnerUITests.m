@import XCTest;
@import patrol;
@import ObjectiveC.runtime;

// Patrol provides the entire iOS test runner via this macro. The Xcode
// project's RunnerUITests target must build this file and link the
// `patrol` Pod (added by `patrol bootstrap` on macOS — see
// `integration_test/README.md`).
PATROL_INTEGRATION_TEST_IOS_RUNNER(RunnerUITests)
