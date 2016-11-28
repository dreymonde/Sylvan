
public enum OptionalUnwrapError : Error {
    case noValue
}

internal extension Optional {
    
    func tryUnwrap() throws -> Wrapped {
        if let value = self {
            return value
        } else {
            throw OptionalUnwrapError.noValue
        }
    }
    
}
