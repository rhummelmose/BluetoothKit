//
//  BKAvailability.swift
//  BluetoothKit
//
//  Created by Rasmus Taulborg Hummelmose on 25/08/15.
//  Copyright © 2015 Wallmob A/S. All rights reserved.
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
