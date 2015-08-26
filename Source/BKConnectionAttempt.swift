//
//  BKConnection.swift
//  BluetoothKit
//
//  Created by Rasmus Taulborg Hummelmose on 25/08/15.
//  Copyright © 2015 Wallmob A/S. All rights reserved.
//

import Foundation

internal func ==(lhs: BKConnectionAttempt, rhs: BKConnectionAttempt) -> Bool {
    return lhs.remotePeripheral.identifier.UUIDString == rhs.remotePeripheral.identifier.UUIDString
}

internal class BKConnectionAttempt: Equatable {
    internal let timer: NSTimer
    internal let remotePeripheral: BKRemotePeripheral
    internal let completionHandler: ((peripheralEntity: BKRemotePeripheral, error: BKConnectionPool.Error?) -> Void)
    internal init(remotePeripheral: BKRemotePeripheral, timer: NSTimer, completionHandler: ((peripheralEntity: BKRemotePeripheral, error: BKConnectionPool.Error?) -> Void)) {
        self.remotePeripheral = remotePeripheral
        self.timer = timer
        self.completionHandler = completionHandler
    }
}
