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

internal func == (lhs: BKSendDataTask, rhs: BKSendDataTask) -> Bool {
    return lhs.destination == rhs.destination && lhs.data == rhs.data
}

internal class BKSendDataTask: Equatable {

    // MARK: Properties

    internal let data: Data
    internal let destination: BKRemotePeer
    internal let completionHandler: BKSendDataCompletionHandler?
    internal var offset = 0

    internal var maximumPayloadLength: Int {
        return destination.maximumUpdateValueLength
    }

    internal var lengthOfRemainingData: Int {
        return data.count - offset
    }

    internal var sentAllData: Bool {
        return lengthOfRemainingData == 0
    }

    internal var rangeForNextPayload: Range<Int>? {
        let lenghtOfNextPayload = maximumPayloadLength <= lengthOfRemainingData ? maximumPayloadLength : lengthOfRemainingData
        let payLoadRange = NSRange(location: offset, length: lenghtOfNextPayload)
        return payLoadRange.toRange()
    }

    internal var nextPayload: Data? {
        if let range = rangeForNextPayload {
             return data.subdata(in: range)
        } else {
            return nil
        }
    }

    // MARK: Initialization

    internal init(data: Data, destination: BKRemotePeer, completionHandler: BKSendDataCompletionHandler?) {
        self.data = data
        self.destination = destination
        self.completionHandler = completionHandler
    }

}
