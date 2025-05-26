import Factory

// This should be a global function but Swift doesn't like global generic functions with default values.
public enum FactoryTestingHelper<C: SharedContainer> {
    /// Asynchronously provides a new container for each operation.
    public static func withContainer(
        shared: TaskLocal<C> = Container.$shared,
        container: @autoclosure @Sendable () -> C = Container(),
        _ operation: () async throws -> Void,
        transform: ContainerTrait<C>.Transform?
    ) async rethrows {
        try await Scope.$singleton.withValue(Scope.singleton.clone()) {
            try await shared.withValue(container()) {
                await transform?(C.shared)
                try await operation()
            }
        }
    }

    public typealias SynchronousTransform = @Sendable (C) -> Void

    /// Synchronous version of `withContainer` for use in non-async contexts.
    public static func withContainer(
        shared: TaskLocal<C> = Container.$shared,
        container: @autoclosure @Sendable () -> C = Container(),
        _ operation: () throws -> Void,
        transform: SynchronousTransform?
    ) rethrows {
        try Scope.$singleton.withValue(Scope.singleton.clone()) {
            try shared.withValue(container()) {
                transform?(C.shared)
                try operation()
            }
        }
    }
}
