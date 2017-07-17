import Foundation

extension Array {
    
    mutating func enqueue(newElement: Element) {
        self.append(newElement)
    }
    
    mutating func dequeue() -> Element? {
        if let element: Element = self.first {
            self.remove(at: 0)
            return element
        } else {
            return nil
        }
    }
}
