import FactoryKit

/// Asynchronously provides a new container and singleton scope for each operation.
public func withContainer<C: SharedContainer>(
    shared: TaskLocal<C>,
    container: @autoclosure @Sendable () -> C,
    operation: () async throws -> Void,
    transform: ContainerTrait<C>.Transform? = nil
) async rethrows {
    try await Scope.$singleton.withValue(Scope.singleton.clone()) {
        try await shared.withValue(container()) {
            await transform?(C.shared)
            try await operation()
        }
    }
}

public typealias SynchronousTransform<C: SharedContainer> = @Sendable (C) -> Void

/// Synchronous version of `withContainer` for use in non-async contexts.
public func withContainer<C: SharedContainer>(
    shared: TaskLocal<C>,
    container: @autoclosure @Sendable () -> C,
    operation: () throws -> Void,
    transform: SynchronousTransform<C>? = nil
) rethrows {
    try Scope.$singleton.withValue(Scope.singleton.clone()) {
        try shared.withValue(container()) {
            transform?(C.shared)
            try operation()
        }
    }
}
