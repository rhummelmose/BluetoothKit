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
import CoreBluetooth

public enum BKAvailability {
    
    case Available
    case Unavailable(cause: BKUnavailabilityCause)
    
    internal init(centralManagerState: CBCentralManagerState) {
        switch centralManagerState {
            case .PoweredOn: self = .Available
            default: self = .Unavailable(cause: BKUnavailabilityCause(centralManagerState: centralManagerState))
        }
    }

    internal init(peripheralManagerState: CBPeripheralManagerState) {
        switch peripheralManagerState {
            case .PoweredOn: self = .Available
            default: self = .Unavailable(cause: BKUnavailabilityCause(peripheralManagerState: peripheralManagerState))
        }
    }
    
}

public enum BKUnavailabilityCause: NilLiteralConvertible {
    
    case Any
    case Resetting
    case Unsupported
    case Unauthorized
    case PoweredOff
    
    public init(nilLiteral: Void) {
        self = Any
    }
    
    internal init(centralManagerState: CBCentralManagerState) {
        switch centralManagerState {
            case .PoweredOff: self = PoweredOff
            case .Resetting: self = Resetting
            case .Unauthorized: self = Unauthorized
            case .Unsupported: self = Unsupported
            default: self = nil
        }
    }
    
    internal init(peripheralManagerState: CBPeripheralManagerState) {
        switch peripheralManagerState {
            case .PoweredOff: self = PoweredOff
            case .Resetting: self = Resetting
            case .Unauthorized: self = Unauthorized
            case .Unsupported: self = Unsupported
            default: self = nil
        }
    }
    
}

public protocol BKAvailabilityDelegate: class {
    func availabilityObserver(availabilityObserver: AnyObject, availabilityDidChange availability: BKAvailability)
    func availabilityObserver(availabilityObserver: AnyObject, unavailabilityCauseDidChange unavailabilityCause: BKUnavailabilityCause)
}
