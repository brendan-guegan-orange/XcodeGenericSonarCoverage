import XCTest

import XcodeGenericSonarCoverageTests

var tests = [XCTestCaseEntry]()
tests += XcodeGenericSonarCoverageTests.allTests()
XCTMain(tests)
