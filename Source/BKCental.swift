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

public protocol BKCentralDelegate: class, BKAvailabilityDelegate {
    func central(central: BKCentral, remotePeripheralDidDisconnect remotePeripheral: BKRemotePeripheral)
}

private let singleton = BKCentral()

public class BKCentral: BKCBCentralManagerStateDelegate, BKConnectionPoolDelegate {
    
    // MARK: Enums
    
    public enum Error: ErrorType {
        case InterruptedByUnavailability(BKUnavailabilityCause)
        case FailedToConnectDueToTimeout
        case InternalError(underlyingError: ErrorType?)
    }
    
    // MARK: Properties
    
    public class var sharedInstance: BKCentral {
        return singleton
    }
    
    public var availability: BKAvailability {
        return BKAvailability(centralManagerState: centralManager.state)
    }
    
    public weak var delegate: BKCentralDelegate?
    
    // MARK: Initializer
    
    public init() {
        centralManagerDelegate = BKCBCentralManagerDelegateProxy(stateDelegate: self, discoveryDelegate: scanner, connectionDelegate: connectionPool)
        stateMachine = BKCentralStateMachine()
        connectionPool.delegate = self;
    }
    
    // MARK: Public Functions
    
    public func start() throws {
        do {
            try stateMachine.handleEvent(.Start)
            centralManager = CBCentralManager(delegate: centralManagerDelegate, queue: nil, options: nil)
            scanner.centralManager = centralManager
            connectionPool.centralManager = centralManager
        } catch let error {
            throw Error.InternalError(underlyingError: error)
        }
    }
    
    public func scanWithDuration(duration: NSTimeInterval = 10, progressHandler: ((newDiscovery: BKRemotePeripheral) -> Void)? = nil, completionHandler: ((result: [BKRemotePeripheral]?, error: Error?) -> Void)?) {
        do {
            try stateMachine.handleEvent(.Scan)
            try scanner.scanWithDuration(duration, progressHandler: progressHandler) { result, error in
                var returnError: Error?
                if error == nil {
                    try! self.stateMachine.handleEvent(.SetAvailable)
                } else {
                    returnError = .InternalError(underlyingError: error)
                }
                completionHandler?(result: result, error: returnError)
            }
        } catch let error {
            completionHandler?(result: nil, error: .InternalError(underlyingError: error))
            return
        }
    }
    
    public func interrupScan() {
        scanner.interruptScan()
    }
    
    public func connect(timeout: NSTimeInterval = 10, remotePeripheral: BKRemotePeripheral, completionHandler: ((remotePeripheral: BKRemotePeripheral, error: Error?) -> Void)) {
        do {
            try stateMachine.handleEvent(.Connect)
            try connectionPool.connectWithTimeout(timeout, remotePeripheral: remotePeripheral) { remotePeripheral, error in
                var returnError: Error?
                if error == nil {
                    try! self.stateMachine.handleEvent(.SetAvailable)
                } else {
                    returnError = .InternalError(underlyingError: error)
                }
                completionHandler(remotePeripheral: remotePeripheral, error: returnError)
            }
        } catch let error {
            completionHandler(remotePeripheral: remotePeripheral, error: .InternalError(underlyingError: error))
            return
        }
    }
    
    // MARK: Internal & Private Properties
    
    private let scanner = BKScanner()
    private let connectionPool = BKConnectionPool()
    private var centralManagerDelegate: BKCBCentralManagerDelegateProxy!
    private var stateMachine: BKCentralStateMachine!
    private var centralManager: CBCentralManager!
    
    // MARK: Internal Functions
    
    internal func setUnavailable(cause: BKUnavailabilityCause, oldCause: BKUnavailabilityCause?) {
        scanner.interruptScan()
        connectionPool.reset()
        if oldCause == nil {
            delegate?.availabilityObserver(self, availabilityDidChange: .Unavailable(cause: cause))
        } else if oldCause != nil && oldCause != cause {
            delegate?.availabilityObserver(self, unavailabilityCauseDidChange: cause)
        }
    }
    
    // MARK: BKCBCentralManagerStateDelegate
    
    internal func centralManagerDidUpdateState(central: CBCentralManager) {
        switch central.state {
            case .Unknown, .Resetting:
                break
            case .Unsupported, .Unauthorized, .PoweredOff:
                let newCause = BKUnavailabilityCause(centralManagerState: central.state)
                switch stateMachine.state {
                    case let .Unavailable(cause):
                        let oldCause = cause
                        try! stateMachine.handleEvent(.SetUnavailable(cause: newCause))
                        setUnavailable(oldCause, oldCause: newCause)
                    default:
                        try! stateMachine.handleEvent(.SetUnavailable(cause: newCause))
                        setUnavailable(newCause, oldCause: nil)
                }
            
            case .PoweredOn:
                let state = stateMachine.state
                try! stateMachine.handleEvent(.SetAvailable)
                switch state {
                    case .Starting, .Unavailable:
                        delegate?.availabilityObserver(self, availabilityDidChange: .Available)
                    default:
                        break
                }
        }
    }
    
    // MARK: BKConnectionPoolDelegate
    
    func connectionPool(connectionPool: BKConnectionPool, remotePeripheralDidDisconnect remotePeripheral: BKRemotePeripheral) {
        delegate?.central(self, remotePeripheralDidDisconnect: remotePeripheral)
    }
    
}
