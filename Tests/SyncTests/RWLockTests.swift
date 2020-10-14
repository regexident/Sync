import XCTest

@testable import Sync

final class RWLockTests: XCTestCase {
    let delay: TimeInterval = 0.1

    func testInit() throws {
        let rwlock = try RWLock(1234)

        let value = try rwlock.read { access in
            access {
                $0
            }
        }

        XCTAssertEqual(value, 1234)
    }

    func testReadDoesNotBlockRead() throws {
        let rwlock = try RWLock(())

        let queue = DispatchQueue(
            label: #function,
            attributes: .concurrent
        )

        // Start a long-lasting read-lock:

        queue.async {
            try! rwlock.read { _ in
                let _ = sleep(10)
            }
        }

        var resultOrNil: Result<(), RWLockWouldBlockError>?

        // Attempt a second overlapping read-lock:

        let group = DispatchGroup()

        group.enter()
        queue.asyncAfter(deadline: .now() + self.delay) {
            defer {
                group.leave()
            }

            resultOrNil = try! rwlock.tryRead { _ in }
        }

        group.wait()

        let result = try XCTUnwrap(resultOrNil)

        switch result {
        case .success(_):
            break
        case .failure(_):
            XCTFail("Expected concurrent write-lock to not block")
        }
    }

    func testWriteBlocksWrite() throws {
        let rwlock = try RWLock(())

        let queue = DispatchQueue(
            label: #function,
            attributes: .concurrent
        )

        // Start a long-lasting write-lock:

        queue.async {
            try! rwlock.write { _ in
                let _ = sleep(10)
            }
        }

        var resultOrNil: Result<(), RWLockWouldBlockError>?

        // Attempt a second overlapping write-lock:

        let group = DispatchGroup()

        group.enter()
        queue.asyncAfter(deadline: .now() + self.delay) {
            defer {
                group.leave()
            }

            resultOrNil = try! rwlock.tryWrite { _ in }
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

    func testReadBlocksWrite() throws {
        let rwlock = try RWLock(())

        let queue = DispatchQueue(
            label: #function,
            attributes: .concurrent
        )

        // Start a long-lasting read-lock:
        queue.async {
            try! rwlock.read { _ in
                let _ = sleep(10)
            }
        }

        var resultOrNil: Result<(), RWLockWouldBlockError>?

        // Attempt a second overlapping write-lock:

        let group = DispatchGroup()

        group.enter()
        queue.asyncAfter(deadline: .now() + self.delay) {
            defer {
                group.leave()
            }

            resultOrNil = try! rwlock.tryWrite { _ in }
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

    func testWriteBlocksRead() throws {
        let rwlock = try RWLock(())

        let queue = DispatchQueue(
            label: #function,
            attributes: .concurrent
        )

        // Start a long-lasting write-lock:
        queue.async {
            try! rwlock.write { _ in
                let _ = sleep(10)
            }
        }

        var resultOrNil: Result<(), RWLockWouldBlockError>?

        // Attempt a second overlapping read-lock:

        let group = DispatchGroup()

        group.enter()
        queue.asyncAfter(deadline: .now() + self.delay) {
            defer {
                group.leave()
            }

            resultOrNil = try! rwlock.tryRead { _ in }
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

    func testReadWithinReadDoesNotBlock() throws {
        let rwlock = try RWLock(())
        try rwlock.read { _ in
            let result = try rwlock.tryRead { _ in }
            if case .failure = result {
                XCTFail("Expected read within read to not block")
            }
        }
    }

    func testReadWithinWriteDeadlocks() throws {
        let rwlock = try RWLock(())
        try rwlock.write { _ in
            XCTAssertThrowsError(
                try rwlock.tryRead { _ in }
            )
        }
    }

    func testWriteWithinReadBlocks() throws {
        let rwlock = try RWLock(())
        try rwlock.read { _ in
            let result = try rwlock.tryWrite { _ in }
            if case .success = result {
                XCTFail("Expected write within read to block")
            }
        }
    }

    func testWriteWithinWriteBlocks() throws {
        let rwlock = try RWLock(())
        try rwlock.write { _ in
            XCTAssertThrowsError(
                try rwlock.tryWrite { _ in }
            )
        }
    }

    func testSmoke() throws {
        let j = 10_000
        let k = 10

        let rwlock = try RWLock(0)

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

                if i % k == 0 {
                    try! rwlock.write { access in
                        access {
                            $0 += 1
                        }
                    }
                } else {
                    try! rwlock.read { _ in }
                }
            }
        }

        group.wait()

        let result = try rwlock.read { access in
            access {
                $0
            }
        }

        XCTAssertEqual(result, j / k)
    }

    static var allTests = [
        ("testInit", testInit),
        ("testReadDoesNotBlockRead", testReadDoesNotBlockRead),
        ("testWriteBlocksWrite", testWriteBlocksWrite),
        ("testReadBlocksWrite", testReadBlocksWrite),
        ("testWriteBlocksRead", testWriteBlocksRead),
        ("testReadWithinReadDoesNotBlock", testReadWithinReadDoesNotBlock),
        ("testReadWithinWriteDeadlocks", testReadWithinWriteDeadlocks),
        ("testWriteWithinReadBlocks", testWriteWithinReadBlocks),
        ("testWriteWithinWriteBlocks", testWriteWithinWriteBlocks),
        ("testSmoke", testSmoke),
    ]
}
