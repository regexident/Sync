import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MutexTests.allTests),
        testCase(RWLockTests.allTests),
    ]
}
#endif
