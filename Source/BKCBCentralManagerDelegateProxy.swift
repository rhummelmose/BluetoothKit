//
//  BKCBCentralManagerDelegateProxy.swift
//  CustomerFacingDisplay
//
//  Created by Rasmus Taulborg Hummelmose on 19/08/15.
//  Copyright © 2015 Wallmob A/S. All rights reserved.
//

import Foundation
import CoreBluetooth

internal protocol BKCBCentralManagerStateDelegate: class {
    func centralManagerDidUpdateState(central: CBCentralManager)
}

internal protocol BKCBCentralManagerDiscoveryDelegate: class {
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber)
}

internal protocol BKCBCentralManagerConnectionDelegate: class {
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral)
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?)
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?)
}

internal class BKCBCentralManagerDelegateProxy: NSObject, CBCentralManagerDelegate {
    
    // MARK: Public Implementation
    
    internal init(stateDelegate: BKCBCentralManagerStateDelegate, discoveryDelegate: BKCBCentralManagerDiscoveryDelegate, connectionDelegate: BKCBCentralManagerConnectionDelegate) {
        self.stateDelegate = stateDelegate
        self.discoveryDelegate = discoveryDelegate
        self.connectionDelegate = connectionDelegate
        super.init()
    }
    
    // MARK: Private Implementation
    
    internal weak var stateDelegate: BKCBCentralManagerStateDelegate?
    internal weak var discoveryDelegate: BKCBCentralManagerDiscoveryDelegate?
    internal weak var connectionDelegate: BKCBCentralManagerConnectionDelegate?
    
    internal func centralManagerDidUpdateState(central: CBCentralManager) {
        stateDelegate?.centralManagerDidUpdateState(central)
    }
    
    internal func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        discoveryDelegate?.centralManager(central, didDiscoverPeripheral: peripheral, advertisementData: advertisementData, RSSI: RSSI)
    }
    
    internal func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        connectionDelegate?.centralManager(central, didConnectPeripheral: peripheral)
    }
    
    internal func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        connectionDelegate?.centralManager(central, didFailToConnectPeripheral: peripheral, error: error)
    }
    
    internal func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        connectionDelegate?.centralManager(central, didDisconnectPeripheral: peripheral, error: error)
    }
}
