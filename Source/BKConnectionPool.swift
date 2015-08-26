//
//  BKyConnectionPool.swift
//  CustomerFacingDisplay
//
//  Created by Rasmus Taulborg Hummelmose on 19/08/15.
//  Copyright © 2015 Wallmob A/S. All rights reserved.
//

import Foundation
import CoreBluetooth

internal protocol BKConnectionPoolDelegate: class {
    func connectionPool(connectionPool: BKConnectionPool, remotePeripheralDidDisconnect remotePeripheral: BKRemotePeripheral)
}

internal class BKConnectionPool: BKCBCentralManagerConnectionDelegate {
    
    // MARK: Internal Implementation
    
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
    
    internal weak var delegate: BKConnectionPoolDelegate?
    
    // MARK: CentralManagerConnectionDelegate
    
    internal var centralManager: CBCentralManager!
    
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
    
    // MARK: Private Implementation
    
    private var connectionAttempts = [BKConnectionAttempt]()
    private var connectedRemotePeripherals = [BKRemotePeripheral]()
    
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
    
}
