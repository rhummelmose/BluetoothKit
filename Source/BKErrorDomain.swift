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

/**
    Errors that can occur when interacting with BluetoothKit.
    - InterruptedByUnavailability(cause): Will be returned if Bluetooth ie. is turned off while performing an action.
    - FailedToConnectDueToTimeout: The time out elapsed while attempting to connect to a peripheral.
    - RemotePeerNotConnected: The action failed because the remote peer attempted to interact with, was not connected.
    - InternalError(underlyingError): Will be returned if any of the internal or private classes returns an unhandled error.
 */
public enum BKError: Error {
    case interruptedByUnavailability(cause: BKUnavailabilityCause)
    case failedToConnectDueToTimeout
    case remotePeerNotConnected
    case internalError(underlyingError: Error?)
}
