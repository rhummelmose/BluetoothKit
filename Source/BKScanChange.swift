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

public func ==(lhs: BKScanChange, rhs: BKScanChange) -> Bool {
    switch (lhs, rhs) {
        case (.Insert(let lhsPeripheral), .Insert(let rhsPeripheral)): return lhsPeripheral == rhsPeripheral || lhsPeripheral == nil || rhsPeripheral == nil
        case (.Remove(let lhsPeripheral), .Remove(let rhsPeripheral)): return lhsPeripheral == rhsPeripheral || lhsPeripheral == nil || rhsPeripheral == nil
        default: return false
    }
}

public enum BKScanChange: Equatable {
    
    case Insert(remotePeripheral: BKRemotePeripheral?)
    case Remove(remotePeripheral: BKRemotePeripheral?)
    
    public var remotePeripheral: BKRemotePeripheral! {
        switch self {
            case .Insert(let remotePeripheral): return remotePeripheral
            case .Remove(let remotePeripheral): return remotePeripheral
        }
    }
    
}
