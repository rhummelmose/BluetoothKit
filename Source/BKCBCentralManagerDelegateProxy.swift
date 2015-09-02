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
    
    // MARK: Initialization
    
    internal init(stateDelegate: BKCBCentralManagerStateDelegate, discoveryDelegate: BKCBCentralManagerDiscoveryDelegate, connectionDelegate: BKCBCentralManagerConnectionDelegate) {
        self.stateDelegate = stateDelegate
        self.discoveryDelegate = discoveryDelegate
        self.connectionDelegate = connectionDelegate
        super.init()
    }
    
    // MARK: Properties
    
    internal weak var stateDelegate: BKCBCentralManagerStateDelegate?
    internal weak var discoveryDelegate: BKCBCentralManagerDiscoveryDelegate?
    internal weak var connectionDelegate: BKCBCentralManagerConnectionDelegate?
    
    // MARK: CBCentralManagerDelegate
    
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
