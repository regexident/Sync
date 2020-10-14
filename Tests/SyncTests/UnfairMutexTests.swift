import XCTest

@testable import Sync

@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
final class UnfairMutexTests: XCTestCase {
    let delay: TimeInterval = 0.1
    
    func testInit() throws {
        let mutex = try UnfairMutex(1234)

        XCTAssertEqual(try mutex.unwrap(), 1234)
    }

    func testRead() throws {
        let mutex = try UnfairMutex(())

        try mutex.read { _ in }
        try mutex.read { _ in }
    }

    func testTryRead() throws {
        let mutex = try UnfairMutex(())

        try mutex.tryRead { _ in }
        try mutex.tryRead { _ in }
    }

    func testWrite() throws {
        let mutex = try UnfairMutex(())

        try mutex.read { _ in }
        try mutex.read { _ in }
    }

    func testTryWrite() throws {
        let mutex = try UnfairMutex(())

        try mutex.tryRead { _ in }
        try mutex.tryRead { _ in }
    }

    func testUnwrap() throws {
        let mutex = try UnfairMutex(42)

        let value = try mutex.unwrap()

        XCTAssertEqual(value, 42)
    }

    func testUseAfterUnwrapThrows() throws {
        let mutex = try UnfairMutex(42)

        let _ = try mutex.unwrap()

        XCTAssertThrowsError(try mutex.read { _ in })
        XCTAssertThrowsError(try mutex.tryRead { _ in })
        XCTAssertThrowsError(try mutex.unwrap())
        XCTAssertThrowsError(try mutex.tryUnwrap())
    }

    func testReentrantLockDeadlocks() throws {
        let mutex = try UnfairMutex(1)
        try mutex.read { _ in
            let result = try mutex.tryRead { _ in }

            switch result {
            case .success(_):
                XCTFail("Expected concurrent write-lock to block")
            case .failure(_):
                break
            }
        }
    }

    func testLockBlocksLock() throws {
        let mutex = try UnfairMutex(())

        let queue = DispatchQueue(
            label: #function,
            attributes: .concurrent
        )

        // Start a long-lasting write-lock:

        queue.async {
            try! mutex.read { _ in
                let _ = sleep(10)
            }
        }

        var resultOrNil: Result<(), MutexWouldBlockError>?

        // Attempt a second overlapping write-lock:

        let group = DispatchGroup()

        group.enter()
        queue.asyncAfter(deadline: .now() + self.delay) {
            defer {
                group.leave()
            }

            resultOrNil = try! mutex.tryRead { _ in }
        }

        group.wait()

        let result = try XCTUnwrap(resultOrNil)

        switch result {
        case .success(_):
            XCTFail("Expected concurrent write-lock to block")
        case .failure(_):
            break
        }
    }

    func testSmoke() throws {
        let j = 10_000
        let k = 10

        let mutex = try UnfairMutex(0)

        let queue = DispatchQueue(
            label: #function,
            attributes: .concurrent
        )

        let group = DispatchGroup()

        for i in 0..<j {
            group.enter()

            queue.async {
                defer {
                    group.leave()
                }

                try! mutex.write { access in
                    if i % k == 0 {
                        access {
                            $0 += 1
                        }
                    }
                }
            }
        }

        group.wait()

        XCTAssertEqual(try mutex.unwrap(), j / k)
    }

    func testExample() throws {
        let mutex = try UnfairMutex(0)

        let count: Int = 1000

        let queue = DispatchQueue(
            label: #function,
            attributes: .concurrent
        )

        let group = DispatchGroup()

        for _ in 0..<count {
            group.enter()

            queue.async {
                defer {
                    group.leave()
                }
                try! mutex.write { access in
                    access {
                        $0 += 2
                    }
                }
            }
        }

        group.wait()

        let value = try! mutex.unwrap()

        XCTAssertEqual(value, 2 * count)
    }

    static var allTests = [
        ("testInit", testInit),
        ("testRead", testRead),
        ("testTryRead", testTryRead),
        ("testWrite", testWrite),
        ("testTryWrite", testTryWrite),
        ("testReentrantLockDeadlocks", testReentrantLockDeadlocks),
        ("testLockBlocksLock", testLockBlocksLock),
        ("testSmoke", testSmoke),
        ("testExample", testExample),
    ]
}
