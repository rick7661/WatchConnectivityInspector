import Foundation
import WatchConnectivity

extension WCSessionController {
    
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    #if os(iOS)
    
    public func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    public func sessionDidDeactivate(_ session: WCSession) {
    }
    
    public func sessionWatchStateDidChange(_ session: WCSession) {
    }
    
    #endif
    
    public func sessionReachabilityDidChange(_ session: WCSession) {
    }
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    }
    
    
    public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Swift.Void) {
    }
    
    
    public func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
    }
    
    
    public func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Swift.Void) {
    }
    
    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
    }
    
    public func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
    }
    
    public func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
    }
    
    public func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
    }
    
    public func session(_ session: WCSession, didReceive file: WCSessionFile) {
    }
}
