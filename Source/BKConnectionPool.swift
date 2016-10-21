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
    func connectionPool(_ connectionPool: BKConnectionPool, remotePeripheralDidDisconnect remotePeripheral: BKRemotePeripheral)
}

internal class BKConnectionPool: BKCBCentralManagerConnectionDelegate {

    // MARK: Enums

    internal enum BKError: Error {
        case noCentralManagerSet
        case alreadyConnected
        case alreadyConnecting
        case connectionByUUIDIsNotImplementedYet
        case interrupted
        case noConnectionAttemptForRemotePeripheral
        case noConnectionForRemotePeripheral
        case timeoutElapsed
        case `internal`(underlyingError: Error?)
    }

    // MARK: Properties

    internal weak var delegate: BKConnectionPoolDelegate?
    internal var centralManager: CBCentralManager!
    internal var connectedRemotePeripherals = [BKRemotePeripheral]()
    private var connectionAttempts = [BKConnectionAttempt]()

    // MARK: Internal Functions

    internal func connectWithTimeout(_ timeout: TimeInterval, remotePeripheral: BKRemotePeripheral, completionHandler: @escaping ((_ peripheralEntity: BKRemotePeripheral, _ error: Error?) -> Void)) throws {
        guard centralManager != nil else {
            throw BKError.noCentralManagerSet
        }
        guard !connectedRemotePeripherals.contains(remotePeripheral) else {
            throw BKError.alreadyConnected
        }
        guard !connectionAttempts.map({ connectionAttempt in return connectionAttempt.remotePeripheral }).contains(remotePeripheral) else {
            throw BKError.alreadyConnecting
        }
        guard remotePeripheral.peripheral != nil else {
            throw BKError.connectionByUUIDIsNotImplementedYet
        }
        let timer = Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(BKConnectionPool.timerElapsed(_:)), userInfo: nil, repeats: false)
        remotePeripheral.prepareForConnection()
        connectionAttempts.append(BKConnectionAttempt(remotePeripheral: remotePeripheral, timer: timer, completionHandler: completionHandler))
        centralManager!.connect(remotePeripheral.peripheral!, options: nil)
    }

    internal func interruptConnectionAttemptForRemotePeripheral(_ remotePeripheral: BKRemotePeripheral) throws {
        let connectionAttempt = connectionAttemptForRemotePeripheral(remotePeripheral)
        guard connectionAttempt != nil else {
            throw BKError.noConnectionAttemptForRemotePeripheral
        }
        failConnectionAttempt(connectionAttempt!, error: .interrupted)
    }

    internal func disconnectRemotePeripheral(_ remotePeripheral: BKRemotePeripheral) throws {
        let connectedRemotePeripheral = connectedRemotePeripherals.filter({ $0 == remotePeripheral }).last
        guard connectedRemotePeripheral != nil else {
            throw BKError.noConnectionForRemotePeripheral
        }
        connectedRemotePeripheral?.unsubscribe()
        centralManager.cancelPeripheralConnection(connectedRemotePeripheral!.peripheral!)
    }

    internal func reset() {
        for connectionAttempt in connectionAttempts {
            failConnectionAttempt(connectionAttempt, error: .interrupted)
        }
        connectionAttempts.removeAll()
        for remotePeripheral in connectedRemotePeripherals {
            delegate?.connectionPool(self, remotePeripheralDidDisconnect: remotePeripheral)
        }
        connectedRemotePeripherals.removeAll()
    }

    // MARK: Private Functions

    private func connectionAttemptForRemotePeripheral(_ remotePeripheral: BKRemotePeripheral) -> BKConnectionAttempt? {
        return connectionAttempts.filter({ $0.remotePeripheral == remotePeripheral }).last
    }

    private func connectionAttemptForTimer(_ timer: Timer) -> BKConnectionAttempt? {
        return connectionAttempts.filter({ $0.timer == timer }).last
    }

    private func connectionAttemptForPeripheral(_ peripheral: CBPeripheral) -> BKConnectionAttempt? {
        return connectionAttempts.filter({ $0.remotePeripheral.peripheral == peripheral }).last
    }

    @objc private func timerElapsed(_ timer: Timer) {
        failConnectionAttempt(connectionAttemptForTimer(timer)!, error: .timeoutElapsed)
    }

    private func failConnectionAttempt(_ connectionAttempt: BKConnectionAttempt, error: BKError) {
        connectionAttempts.remove(at: connectionAttempts.index(of: connectionAttempt)!)
        connectionAttempt.timer.invalidate()
        if let peripheral = connectionAttempt.remotePeripheral.peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectionAttempt.completionHandler(connectionAttempt.remotePeripheral, error)
    }

    private func succeedConnectionAttempt(_ connectionAttempt: BKConnectionAttempt) {
        connectionAttempt.timer.invalidate()
        connectionAttempts.remove(at: connectionAttempts.index(of: connectionAttempt)!)
        connectedRemotePeripherals.append(connectionAttempt.remotePeripheral)
        connectionAttempt.remotePeripheral.discoverServices()
        connectionAttempt.completionHandler(connectionAttempt.remotePeripheral, nil)
    }

    // MARK: CentralManagerConnectionDelegate

    internal func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let attempt = connectionAttemptForPeripheral(peripheral) else {
            // http://stackoverflow.com/questions/11557500/corebluetooth-central-manager-callback-diddiscoverperipheral-twice
            return
        }
        succeedConnectionAttempt(attempt)
    }

    internal func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard let attempt = connectionAttemptForPeripheral(peripheral) else {
            // Calling failConnection cause this method to be called without an attempt being present.
            return
        }
        failConnectionAttempt(attempt, error: .internal(underlyingError: error))
    }

    internal func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let remotePeripheral = connectedRemotePeripherals.filter({ $0.peripheral == peripheral }).last {
            connectedRemotePeripherals.remove(at: connectedRemotePeripherals.index(of: remotePeripheral)!)
            delegate?.connectionPool(self, remotePeripheralDidDisconnect: remotePeripheral)
        }
    }

}
