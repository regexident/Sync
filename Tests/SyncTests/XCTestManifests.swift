import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    let unfairMutexTests: XCTestCaseEntry?

    if #available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *) {
        unfairMutexTests = testCase(UnfairMutexTests.allTests)
    } else {
        unfairMutexTests = nil
    }

    return [
        testCase(MutexTests.allTests),
        testCase(RWLockTests.allTests),
        unfairMutexTests,
    ].compactMap { $0 }
}
#endif
