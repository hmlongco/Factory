/// Used by `@Dependency(mode: .optional)` to wrap a resolved value in `Optional`
/// without double-wrapping when the factory already returns an optional.
///
/// The compiler picks the correct overload at the call site:
/// - `T`  → `T?`
/// - `T?` → `T?`  (pass-through, avoids `T??`)
@inline(__always) public func _wrapOptional<T>(_ value: T)  -> T? { value }
@inline(__always) public func _wrapOptional<T>(_ value: T?) -> T? { value }
