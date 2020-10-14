# Sync

Useful synchronization primitives in Swift.

## `Mutex`

A mutual exclusion primitive useful for protecting shared data

> This mutex will block threads waiting for the lock to become available.
> The mutex can also be statically initialized or created via a new
> constructor. Each mutex has a type parameter which represents the data
> that it is protecting. The data can only be accessed through the `access`
> handle passed to the callback of `lock` and `tryLock`, which guarantees
> that the data is only ever accessed when the mutex is locked.

### Minimal Example

```swift
let mutex = try Mutex(0)

try! mutex.read { value in 
    print(value)
}

try! mutex.write { access in
    access { value in
        value += 42
    }
}
```

### Real-world Example

```swift
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
```

## `RWLock`

A reader-writer lock

> This type of lock allows a number of readers or at most one writer
> at any point in time. The write portion of this lock typically allows
> modification of the underlying data (exclusive access) and the read
> portion of this lock typically allows for read-only access (shared access).
>
> In comparison, a `Mutex` does not distinguish between readers or writers
> that acquire the lock, therefore blocking any threads waiting for the
> lock to become available. An `RWLock` will allow any number of readers
> to acquire the lock as long as a writer is not holding the lock.
> 
> **Important**: `RWLock` does not support priority inversion avoidance.

### Minimal Example

```swift
let rwlock = try RWLock(0)

try! rwlock.read { value in 
    print(value)
}

try! rwlock.write { access in
    access { value in
        value += 42
    }
}
```

### Real-world Example

```swift
let rwlock = try RWLock(0)

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
        try! rwlock.write { access in
            access {
                $0 += 2
            }
        }
    }
}

group.wait()

let value = try! rwlock.unwrap()

XCTAssertEqual(value, 2 * count)
```
