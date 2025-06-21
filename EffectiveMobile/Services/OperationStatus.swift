import Foundation
import CasePaths

@CasePathable
public enum OperationStatus<V, E>: Sendable where V: Sendable, E: Sendable {
    case start
    case complete(V)
    case fail(E)
}

@CasePathable
public enum OperationStatusWithParam<V, P, E>: Sendable where V: Sendable, P: Sendable, E: Sendable {
    case start(P)
    case complete(P, V)
    case fail(P, E)
}
