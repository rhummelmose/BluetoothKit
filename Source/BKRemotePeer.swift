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

public protocol BKRemotePeerDelegate: class {
    /**
     Called when the remote peer sent data.
     - parameter remotePeripheral: The remote peripheral that sent the data.
     - parameter data: The data it sent.
     */
    func remotePeer(_ remotePeer: BKRemotePeer, didSendArbitraryData data: Data)
}

public func == (lhs: BKRemotePeer, rhs: BKRemotePeer) -> Bool {
    return (lhs.identifier == rhs.identifier)
}

public class BKRemotePeer: Equatable {

    /// A unique identifier for the peer, derived from the underlying CBCentral or CBPeripheral object, or set manually.
    public let identifier: UUID

    public weak var delegate: BKRemotePeerDelegate?

    internal var configuration: BKConfiguration?
    private var data: Data?

    init(identifier: UUID) {
        self.identifier = identifier
    }

    internal var maximumUpdateValueLength: Int {
        return 20
    }

    internal func handleReceivedData(_ receivedData: Data) {
        if receivedData == configuration!.endOfDataMark {
            if let finalData = data {
                delegate?.remotePeer(self, didSendArbitraryData: finalData)
            }
            data = nil
            return
        }
        if self.data != nil {
            self.data?.append(receivedData)
            return
        }
        self.data = receivedData
    }

}
