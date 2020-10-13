import XCTest

import SyncTests

var tests = [XCTestCaseEntry]()
tests += SyncTests.allTests()
XCTMain(tests)
