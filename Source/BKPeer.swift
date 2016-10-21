//
//  BluetoothKit
//
//  Copyright (c) 2015 Rasmus Taulborg Hummelmose - https://github.com/rasmusth
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

public typealias BKSendDataCompletionHandler = ((_ data: Data, _ remotePeer: BKRemotePeer, _ error: BKError?) -> Void)

public class BKPeer {

    /// The configuration the BKCentral object was started with.
    public var configuration: BKConfiguration? {
        return nil
    }

    internal var connectedRemotePeers: [BKRemotePeer] {
        get {
            return _connectedRemotePeers
        }
        set {
            _connectedRemotePeers = newValue
        }
    }

    internal var sendDataTasks: [BKSendDataTask] = []

    private var _connectedRemotePeers: [BKRemotePeer] = []

    /**
     Sends data to a connected remote central.
     - parameter data: The data to send.
     - parameter remotePeer: The destination of the data payload.
     - parameter completionHandler: A completion handler allowing you to react in case the data failed to send or once it was sent succesfully.
     */
    public func sendData(_ data: Data, toRemotePeer remotePeer: BKRemotePeer, completionHandler: BKSendDataCompletionHandler?) {
        guard connectedRemotePeers.contains(remotePeer) else {
            completionHandler?(data, remotePeer, BKError.remotePeerNotConnected)
            return
        }
        let sendDataTask = BKSendDataTask(data: data, destination: remotePeer, completionHandler: completionHandler)
        sendDataTasks.append(sendDataTask)
        if sendDataTasks.count == 1 {
            processSendDataTasks()
        }
    }

    internal func processSendDataTasks() {
        guard sendDataTasks.count > 0 else {
            return
        }
        let nextTask = sendDataTasks.first!
        if nextTask.sentAllData {
            let sentEndOfDataMark = sendData(configuration!.endOfDataMark, toRemotePeer: nextTask.destination)
            if sentEndOfDataMark {
                sendDataTasks.remove(at: sendDataTasks.index(of: nextTask)!)
                nextTask.completionHandler?(nextTask.data, nextTask.destination, nil)
                processSendDataTasks()
            } else {
                return
            }
        }
        if let nextPayload = nextTask.nextPayload {
            let sentNextPayload = sendData(nextPayload, toRemotePeer: nextTask.destination)
            if sentNextPayload {
                nextTask.offset += nextPayload.count
                processSendDataTasks()
            } else {
                return
            }
        } else {
            return
        }

    }

    internal func failSendDataTasksForRemotePeer(_ remotePeer: BKRemotePeer) {
        for sendDataTask in sendDataTasks.filter({ $0.destination == remotePeer }) {
            sendDataTasks.remove(at: sendDataTasks.index(of: sendDataTask)!)
            sendDataTask.completionHandler?(sendDataTask.data, sendDataTask.destination, .remotePeerNotConnected)
        }
    }

    internal func sendData(_ data: Data, toRemotePeer remotePeer: BKRemotePeer) -> Bool {
        fatalError("Function must be overridden by subclass")
    }

}
