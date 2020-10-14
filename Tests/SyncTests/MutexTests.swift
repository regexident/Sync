import XCTest

@testable import Sync

final class MutexTests: XCTestCase {
    let delay: TimeInterval = 0.1
    
    func testInit() throws {
        let mutex = try Mutex(1234)

        let value = try mutex.lock { access in
            access {
                $0
            }
        }

        XCTAssertEqual(value, 1234)
    }

    func testLock() throws {
        let mutex = try Mutex(())

        try mutex.lock { _ in }
        try mutex.lock { _ in }
    }

    func testTryLock() throws {
        let mutex = try Mutex(())

        try mutex.tryLock { _ in }
        try mutex.tryLock { _ in }
    }

    func testReentrantLockWithNonRecursive() throws {
        let mutex = try Mutex(1, type: .default)
        try mutex.lock { inner in
            let result = try mutex.tryLock { _ in }

            switch result {
            case .success(_):
                XCTFail("Expected concurrent write-lock to block")
            case .failure(_):
                break
            }
        }
    }

    func testReentrantLockWithRecursive() throws {
        let mutex = try Mutex(1, type: .recursive)
        try mutex.lock { inner in
            let result = try mutex.tryLock { _ in }

            switch result {
            case .success(_):
                break
            case .failure(_):
                XCTFail("Expected concurrent write-lock to not block")
            }
        }
    }

    func testLockBlocksLock() throws {
        let mutex = try Mutex(())

        let queue = DispatchQueue(
            label: #function,
            attributes: .concurrent
        )

        // Start a long-lasting write-lock:

        queue.async {
            try! mutex.lock { _ in
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

            resultOrNil = try! mutex.tryLock { _ in }
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

        let mutex = try Mutex(0)

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

                try! mutex.lock { access in
                    if i % k == 0 {
                        access {
                            $0 += 1
                        }
                    }
                }
            }
        }

        group.wait()

        let result = try mutex.lock { access in
            access { $0 }
        }

        XCTAssertEqual(result, j / k)
    }

    func testExample() throws {
        let mutex = try Mutex(0)

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
                try! mutex.lock { access in
                    access {
                        $0 += 2
                    }
                }
            }
        }

        group.wait()

        let value = try! mutex.lock { access in
            access {
                $0
            }
        }

        assert(value == 2 * count)
    }

    static var allTests = [
        ("testInit", testInit),
        ("testLock", testLock),
        ("testTryLock", testTryLock),
        ("testReentrantLockWithNonRecursive", testReentrantLockWithNonRecursive),
        ("testReentrantLockWithRecursive", testReentrantLockWithRecursive),
        ("testLockBlocksLock", testLockBlocksLock),
        ("testSmoke", testSmoke),
        ("testExample", testExample),
    ]
}
