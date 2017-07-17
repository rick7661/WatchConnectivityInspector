import Foundation
import WatchConnectivity

public typealias InteractiveMessagingReplyHandler = (Dictionary<String, Any>) -> Void
public typealias InteractiveMessagingErrorHandler = (Error) -> Void
private typealias InteractiveMessageQueue = Array<WCInteractiveMessage>

public protocol InteractiveMessagingDelegate : NSObjectProtocol {
    
    func didReceive(message: Dictionary<String, Any>, replyHandler: InteractiveMessagingReplyHandler)
}

public protocol BackgroundTransferDelegate : NSObjectProtocol {
    
}

// MARK: WCSessionController

public class WCSessionController: NSObject, WCSessionDelegate {
    
    struct Constants {
        static let OutgoingInteractiveMessageTimeoutInterval: TimeInterval = 3.0
        static let SentInteractiveMessageTimeoutInterval: TimeInterval = 3.0
    }
    
    // MARK: Public properties
    
    public var isWCSessionSupported: Bool {
        get {
            return WCSession.isSupported()
        }
    }
    
    public var isCounterpartAppRechable: Bool {
        get {
            if let session: WCSession = self.session {
                return session.isReachable
            } else {
                return false
            }
        }
    }
    
    #if os(iOS)
    
    public var isWatchPaired: Bool {
        get {
            if let session: WCSession = self.session {
                return session.isPaired
            } else {
                return false
            }
        }
    }
    
    public var isWatchAppInstalled: Bool {
        get {
            if let session: WCSession = self.session {
                return session.isWatchAppInstalled
            } else {
                return false
            }
        }
    }
    
    #endif
    
    // MARK: Private properties
    
    private var session: WCSession? = nil
    private var outgoingInteractiveMessageQueue: InteractiveMessageQueue = InteractiveMessageQueue()
    private var sentInteractiveMessageQueue: InteractiveMessageQueue = InteractiveMessageQueue()
    private var outgoingInteractiveMessageTimer: Timer? = nil
    private var sentInteractiveMessageTimer: Timer? = nil
    
    // MARK: Singleton
    
    static let sharedInstance = WCSessionController()
    
    // MARK: Initializer
    
    override private init() {
        super.init()
        if WCSession.isSupported() {
            self.session = WCSession.default()
            if let session = self.session {
                session.delegate = self
            }
        }
    }
    
    // MARK: Send Interactive Message
    
    public func send(message: Dictionary<String, Any>,
                     replyHandler: InteractiveMessagingReplyHandler?,
                     errorHandler: InteractiveMessagingErrorHandler?) {
        if let session: WCSession = self.session {
            session.activate()
            let outgoingMessage: WCInteractiveMessage = WCInteractiveMessage.init(message: message, replyHandler: replyHandler, errorHandler: errorHandler)
            self.enqueue(message: outgoingMessage, queue: &self.outgoingInteractiveMessageQueue, resetTimer: true)
            // dispatch
        } else {
            // creat error
        }
    }
    
    // MARK: Message queue
    
    private func enqueue(message: WCInteractiveMessage, queue: inout InteractiveMessageQueue, resetTimer: Bool) {
        queue.enqueue(newElement: message)
        if resetTimer {
            self.resetOutgoingInteractiveMessageTimer()
        }
    }
    
    private func sendInteractiveMessagesFromOutgoingQueue() {
        while (self.outgoingInteractiveMessageQueue.count > 0) {
            if let outgoingMessage: WCInteractiveMessage = self.outgoingInteractiveMessageQueue.dequeue() {
                self.sendInteractiveMessage(outgoingMessage: outgoingMessage)
            }
        }
    }
    
    private func sendInteractiveMessage(outgoingMessage: WCInteractiveMessage) {
        let message: Dictionary<String, Any> = outgoingMessage.message
        guard let session: WCSession = self.session else {
            let error: Error = NSError(domain: WatchConnectivitySessionErrorDomain, code: WCError.sessionNotSupported.rawValue, userInfo: nil)
            if let errorHandler: InteractiveMessagingErrorHandler  = outgoingMessage.timedErrorHandler {
                errorHandler(error)
            }
            return
        }
        if session.activationState != .activated {
            self.enqueue(message: outgoingMessage, queue: &self.outgoingInteractiveMessageQueue, resetTimer: false)
            return
        }
        if !session.isReachable {
            let error: Error = NSError(domain: WatchConnectivitySessionErrorDomain, code: WCError.notReachable.rawValue, userInfo: nil)
            self.cancelMessagesIn(queue: &self.outgoingInteractiveMessageQueue, error: error)
        }
        session.sendMessage(message,
                            replyHandler: outgoingMessage.replyHandler,
                            errorHandler: outgoingMessage.errorHandler)
        guard let _ = outgoingMessage.replyHandler else {
            outgoingMessage.status = .sentAndNoNeedForReply
            return
        }
        self.enqueue(message: outgoingMessage, queue: &sentInteractiveMessageQueue, resetTimer: true)
        outgoingMessage.status = .sentAndAwaitsReply
    }
    
    // MARK: Message queue timeout
    
    private func resetOutgoingInteractiveMessageTimer() {
        self.stopOutgoingInteractiveMessageTimer()
        self.outgoingInteractiveMessageTimer = Timer.scheduledTimer(withTimeInterval: Constants.OutgoingInteractiveMessageTimeoutInterval, repeats: false, block: { (timer) in
            let error: Error = NSError(domain: WatchConnectivitySessionErrorDomain, code: WatchConnectivitySessionError.outgoingIMTimeout.rawValue, userInfo: nil)
            self.cancelMessagesIn(queue: &self.outgoingInteractiveMessageQueue, error: error)
        })
    }
    
    private func stopOutgoingInteractiveMessageTimer() {
        if let timer: Timer = self.outgoingInteractiveMessageTimer {
            timer.invalidate()
            self.outgoingInteractiveMessageTimer = nil
        }
    }
    
    private func stopSentInteractiveMessageTimer() {
        if let timer: Timer = self.sentInteractiveMessageTimer {
            timer.invalidate()
            self.sentInteractiveMessageTimer = nil
        }
    }
    
    private func cancelMessagesIn(queue: inout InteractiveMessageQueue, error: Error) {
        while queue.count > 0 {
            if let message: WCInteractiveMessage = queue.dequeue(),
               let errorHandler: InteractiveMessagingErrorHandler = message.errorHandler {
                errorHandler(error)
            }
        }
    }
}

// MARK: OutgoingInteractiveMessage inner class

private class WCInteractiveMessage: NSObject {
    
    enum OutgoingIMStatus {
        case notSent
        case sentAndAwaitsReply
        case sentAndNoNeedForReply
        case repliedOnTime
        case repliedAfterTimeout
    }
    
    var message: Dictionary<String, Any> = Dictionary<String, Any>()
    var replyHandler: InteractiveMessagingReplyHandler?
    var errorHandler: InteractiveMessagingErrorHandler?
    var timedReplyHandler: InteractiveMessagingReplyHandler?
    var timedErrorHandler: InteractiveMessagingErrorHandler?
    var messageCreationTime: Date = Date.init(timeIntervalSinceReferenceDate: Date.timeIntervalSinceReferenceDate)
    var status: OutgoingIMStatus = .notSent
    
    @available(*, unavailable)
    override init() {
        super.init()
    }
    
    init(message: Dictionary<String, Any>, replyHandler: InteractiveMessagingReplyHandler?, errorHandler: InteractiveMessagingErrorHandler?) {
        super.init()
        self.message = message
        if let handler = replyHandler {
            self.replyHandler = handler
        }
        if let handler = errorHandler {
            self.errorHandler = handler
        }
        self.timedReplyHandler = {[weak self] replyMessage in
            if let strongSelf = self {
                let blockInvocationTime: Date = Date.init(timeIntervalSinceReferenceDate: Date.timeIntervalSinceReferenceDate)
                let elapsed: TimeInterval = blockInvocationTime.timeIntervalSince(strongSelf.messageCreationTime)
                if elapsed > WCSessionController.Constants.SentInteractiveMessageTimeoutInterval {
                    strongSelf.status = .repliedAfterTimeout
                    return
                }
                strongSelf.status = .repliedOnTime
                if let handler: InteractiveMessagingReplyHandler = strongSelf.replyHandler {
                    handler(replyMessage)
                }
            }
        }
        self.timedErrorHandler = {[weak self] error in
            if let strongSelf = self {
                let blockInvocationTime: Date = Date.init(timeIntervalSinceReferenceDate: Date.timeIntervalSinceReferenceDate)
                let elapsed: TimeInterval = blockInvocationTime.timeIntervalSince(strongSelf.messageCreationTime)
                if elapsed > WCSessionController.Constants.SentInteractiveMessageTimeoutInterval {
                    strongSelf.status = .repliedAfterTimeout
                    return
                }
                strongSelf.status = .repliedOnTime
                if let handler: InteractiveMessagingErrorHandler = strongSelf.errorHandler {
                    handler(error)
                }
            }
        }
    }
}
