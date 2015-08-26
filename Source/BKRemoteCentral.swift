//
//  BKRemoteCentral.swift
//  BluetoothKit
//
//  Created by Rasmus Taulborg Hummelmose on 25/08/15.
//  Copyright © 2015 Wallmob A/S. All rights reserved.
//

import Foundation
import CoreBluetooth

public func ==(lhs: BKRemoteCentral, rhs: BKRemoteCentral) -> Bool {
    return lhs.identifier.isEqual(rhs.identifier)
}

public struct BKRemoteCentral: Equatable {
    
    internal let central: CBCentral
    internal var identifier: NSUUID {
        return central.identifier
    }
    
    internal init(central: CBCentral) {
        self.central = central
    }
    
}
