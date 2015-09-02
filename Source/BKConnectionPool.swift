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

internal protocol BKConnectionPoolDelegate: class {
    func connectionPool(connectionPool: BKConnectionPool, remotePeripheralDidDisconnect remotePeripheral: BKRemotePeripheral)
}

internal class BKConnectionPool: BKCBCentralManagerConnectionDelegate {
    
    // MARK: Enums
    
    internal enum Error: ErrorType {
        case NoCentralManagerSet
        case AlreadyConnected
        case AlreadyConnecting
        case NoSupportForPeripheralEntitiesWithoutPeripheralsYet
        case Interrupted
        case NoConnectionAttemptForRemotePeripheral
        case NoConnectionForRemotePeripheral
        case TimeoutElapsed
        case Internal(underlyingError: ErrorType?)
    }
    
    // MARK: Properties
    
    internal weak var delegate: BKConnectionPoolDelegate?
    internal var centralManager: CBCentralManager!
    internal var connectedRemotePeripherals = [BKRemotePeripheral]()
    private var connectionAttempts = [BKConnectionAttempt]()
    
    // MARK: Internal Functions
    
    internal func connectWithTimeout(timeout: NSTimeInterval, remotePeripheral: BKRemotePeripheral, completionHandler: ((peripheralEntity: BKRemotePeripheral, error: Error?) -> Void)) throws {
        guard centralManager != nil else {
            throw Error.NoCentralManagerSet
        }
        guard !connectedRemotePeripherals.contains(remotePeripheral) else {
            throw Error.AlreadyConnected
        }
        guard !connectionAttempts.map({ connectionAttempt in return connectionAttempt.remotePeripheral }).contains(remotePeripheral) else {
            throw Error.AlreadyConnecting
        }
        guard remotePeripheral.peripheral != nil else {
            throw Error.NoSupportForPeripheralEntitiesWithoutPeripheralsYet
        }
        let timer = NSTimer.scheduledTimerWithTimeInterval(timeout, target: self, selector: "timerElapsed:", userInfo: nil, repeats: false)
        remotePeripheral.prepareForConnection()
        connectionAttempts.append(BKConnectionAttempt(remotePeripheral: remotePeripheral, timer: timer, completionHandler: completionHandler))
        centralManager!.connectPeripheral(remotePeripheral.peripheral!, options: nil)
    }
    
    internal func interruptConnectionAttemptForRemotePeripheral(remotePeripheral: BKRemotePeripheral) throws {
        let connectionAttempt = connectionAttemptForRemotePeripheral(remotePeripheral)
        guard connectionAttempt != nil else {
            throw Error.NoConnectionAttemptForRemotePeripheral
        }
        failConnectionAttempt(connectionAttempt!, error: .Interrupted)
    }
    
    internal func disconnectRemotePeripheral(remotePeripheral: BKRemotePeripheral) throws {
        let connectedRemotePeripheral = connectedRemotePeripherals.filter({ $0 == remotePeripheral }).last
        guard connectedRemotePeripheral != nil else {
            throw Error.NoConnectionForRemotePeripheral
        }
        connectedRemotePeripheral?.unsubscribe()
        centralManager.cancelPeripheralConnection(connectedRemotePeripheral!.peripheral!)
    }
    
    internal func reset() {
        for connectionAttempt in connectionAttempts {
            failConnectionAttempt(connectionAttempt, error: .Interrupted)
        }
        connectionAttempts.removeAll()
        for remotePeripheral in connectedRemotePeripherals {
            delegate?.connectionPool(self, remotePeripheralDidDisconnect: remotePeripheral)
        }
        connectedRemotePeripherals.removeAll()
    }
    
    // MARK: Private Functions
    
    private func connectionAttemptForRemotePeripheral(remotePeripheral: BKRemotePeripheral) -> BKConnectionAttempt? {
        return connectionAttempts.filter({ $0.remotePeripheral == remotePeripheral }).last
    }
    
    private func connectionAttemptForTimer(timer: NSTimer) -> BKConnectionAttempt? {
        return connectionAttempts.filter({ $0.timer == timer }).last
    }
    
    private func connectionAttemptForPeripheral(peripheral: CBPeripheral) -> BKConnectionAttempt? {
        return connectionAttempts.filter({ $0.remotePeripheral.peripheral == peripheral }).last
    }
    
    @objc private func timerElapsed(timer: NSTimer) {
        failConnectionAttempt(connectionAttemptForTimer(timer)!, error: .TimeoutElapsed)
    }
    
    private func failConnectionAttempt(connectionAttempt: BKConnectionAttempt, error: Error) {
        connectionAttempts.removeAtIndex(connectionAttempts.indexOf(connectionAttempt)!)
        connectionAttempt.timer.invalidate()
        if let peripheral = connectionAttempt.remotePeripheral.peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectionAttempt.completionHandler(peripheralEntity: connectionAttempt.remotePeripheral, error: error)
    }
    
    private func succeedConnectionAttempt(connectionAttempt: BKConnectionAttempt) {
        connectionAttempt.timer.invalidate()
        connectionAttempts.removeAtIndex(connectionAttempts.indexOf(connectionAttempt)!)
        connectedRemotePeripherals.append(connectionAttempt.remotePeripheral)
        connectionAttempt.remotePeripheral.discoverServices()
        connectionAttempt.completionHandler(peripheralEntity: connectionAttempt.remotePeripheral, error: nil)
    }
    
    // MARK: CentralManagerConnectionDelegate
    
    internal func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        succeedConnectionAttempt(connectionAttemptForPeripheral(peripheral)!)
    }
    
    internal func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        failConnectionAttempt(connectionAttemptForPeripheral(peripheral)!, error: .Internal(underlyingError: error))
    }
    
    internal func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        if let remotePeripheral = connectedRemotePeripherals.filter({ $0.peripheral == peripheral }).last {
            connectedRemotePeripherals.removeAtIndex(connectedRemotePeripherals.indexOf(remotePeripheral)!)
            delegate?.connectionPool(self, remotePeripheralDidDisconnect: remotePeripheral)
        }
    }
    
}
