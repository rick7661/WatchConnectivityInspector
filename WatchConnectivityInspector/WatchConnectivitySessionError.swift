import Foundation
import WatchConnectivity

public let WatchConnectivitySessionErrorDomain: String = "WatchConnectivitySessionErrorDomain"

public struct WatchConnectivitySessionError {
    
    public enum Code : Int {
        case outgoingIMTimeout
        case sentIMTimeout
    }
    
    public static var outgoingIMTimeout: WatchConnectivitySessionError.Code {
        get {
            return WatchConnectivitySessionError.Code.outgoingIMTimeout
        }
    }
    
    public static var sentIMTimeout: WatchConnectivitySessionError.Code {
        get {
            return WatchConnectivitySessionError.Code.sentIMTimeout
        }
    }
}
