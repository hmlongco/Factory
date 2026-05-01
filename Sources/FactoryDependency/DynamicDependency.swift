/// Backs `@Dependency(mode: .dynamic)` — resolves fresh from the container on every access.
///
/// The `@autoclosure @escaping` initializer captures the factory call as a deferred closure
/// rather than evaluating it immediately, so `wrappedValue` always calls through to the
/// container. Swift infers the generic `T` from the expression passed as `wrappedValue`,
/// so no explicit type annotation is needed on the generated property.
@propertyWrapper
public struct DynamicDependency<T> {
    private let _resolve: () -> T

    public init(wrappedValue: @autoclosure @escaping () -> T) {
        _resolve = wrappedValue
    }

    public var wrappedValue: T { _resolve() }
}
