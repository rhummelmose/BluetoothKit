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

/**
    The central's delegate is called when asynchronous events occur.
*/
public protocol BKCentralDelegate: class {
    /**
        Called when a remote peripheral disconnects or is disconnected.
        - parameter central: The central from which it disconnected.
        - parameter remotePeripheral: The remote peripheral that disconnected.
    */
    func central(central: BKCentral, remotePeripheralDidDisconnect remotePeripheral: BKRemotePeripheral)
}

private let singleton = BKCentral()

/**
    The class used to take the Bluetooth LE central role. The central discovers remote peripherals by scanning
    and connects to them. When a connection is established the central can receive data from the remote peripheral.
*/
public class BKCentral: BKCBCentralManagerStateDelegate, BKConnectionPoolDelegate, BKAvailabilityObservable {
    
    // MARK: Type Aliases
    
    public typealias ScanProgressHandler = ((newDiscoveries: [BKRemotePeripheral]) -> Void)
    public typealias ScanCompletionHandler = ((result: [BKRemotePeripheral]?, error: Error?) -> Void)
    public typealias ContinuousScanChangeHandler = ((changes: [BKScanChange], peripherals: [BKRemotePeripheral]) -> Void)
    public typealias ContinuousScanStateHandler = ((newState: ContinuousScanState) -> Void)
    public typealias ContinuousScanErrorHandler = ((error: Error) -> Void)
    public typealias ConnectCompletionHandler = ((remotePeripheral: BKRemotePeripheral, error: Error?) -> Void)
    
    // MARK: Enums
    
    public enum Error: ErrorType {
        case InterruptedByUnavailability(BKUnavailabilityCause)
        case FailedToConnectDueToTimeout
        case InternalError(underlyingError: ErrorType?)
    }
    
    public enum ContinuousScanState {
        case Stopped
        case Scanning
        case Waiting
    }
    
    // MARK: Properties
    
    public class var sharedInstance: BKCentral {
        return singleton
    }
    
    public var availability: BKAvailability {
        return BKAvailability(centralManagerState: centralManager.state)
    }
    
    public var connectedRemotePeripherals: [BKRemotePeripheral] {
        return connectionPool.connectedRemotePeripherals
    }
    
    public weak var delegate: BKCentralDelegate?
    public var availabilityObservers = [BKWeakAvailabilityObserver]()
    
    private let scanner = BKScanner()
    private var continuousScanner: BKContinousScanner!
    private let connectionPool = BKConnectionPool()
    private var centralManagerDelegate: BKCBCentralManagerDelegateProxy!
    private var stateMachine: BKCentralStateMachine!
    private var centralManager: CBCentralManager!
    
    // MARK: Initialization
    
    public init() {
        centralManagerDelegate = BKCBCentralManagerDelegateProxy(stateDelegate: self, discoveryDelegate: scanner, connectionDelegate: connectionPool)
        stateMachine = BKCentralStateMachine()
        connectionPool.delegate = self;
        continuousScanner = BKContinousScanner(scanner: scanner)
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
    
    public func scanWithDuration(duration: NSTimeInterval = 3, progressHandler: ScanProgressHandler?, completionHandler: ScanCompletionHandler?) {
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
    
    public func scanContinuouslyWithChangeHandler(changeHandler: ContinuousScanChangeHandler, stateHandler: ContinuousScanStateHandler?, duration: NSTimeInterval = 3, inBetweenDelay: NSTimeInterval = 3, errorHandler: ContinuousScanErrorHandler?) {
        do {
            try stateMachine.handleEvent(.Scan)
            continuousScanner.scanContinuouslyWithChangeHandler(changeHandler, stateHandler: { newState in
                if newState == .Stopped && self.availability == .Available {
                    try! self.stateMachine.handleEvent(.SetAvailable)
                }
                stateHandler?(newState: newState)
            }, duration: duration, inBetweenDelay: inBetweenDelay, errorHandler: { error in
                errorHandler?(error: .InternalError(underlyingError: error))
            })
        } catch let error {
            errorHandler?(error: .InternalError(underlyingError: error))
        }
    }
    
    public func interrupScan() {
        continuousScanner.interruptScan()
        scanner.interruptScan()
    }
    
    public func connect(timeout: NSTimeInterval = 3, remotePeripheral: BKRemotePeripheral, completionHandler: ConnectCompletionHandler) {
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
    
    public func disconnectRemotePeripheral(remotePeripheral: BKRemotePeripheral) throws {
        do {
            try connectionPool.disconnectRemotePeripheral(remotePeripheral)
        } catch let error {
            throw Error.InternalError(underlyingError: error)
        }
    }
    
    public func stop() throws {
        do {
            try stateMachine.handleEvent(.Stop)
            interrupScan()
            connectionPool.reset()
            centralManager = nil
        } catch let error {
            throw Error.InternalError(underlyingError: error)
        }
    }
    
    // MARK: Internal Functions
    
    internal func setUnavailable(cause: BKUnavailabilityCause, oldCause: BKUnavailabilityCause?) {
        scanner.interruptScan()
        connectionPool.reset()
        if oldCause == nil {
            for availabilityObserver in availabilityObservers {
                availabilityObserver.availabilityObserver?.availabilityObserver(self, availabilityDidChange: .Unavailable(cause: cause))
            }
        } else if oldCause != nil && oldCause != cause {
            for availabilityObserver in availabilityObservers {
                availabilityObserver.availabilityObserver?.availabilityObserver(self, unavailabilityCauseDidChange: cause)
            }
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
                        for availabilityObserver in availabilityObservers {
                            availabilityObserver.availabilityObserver?.availabilityObserver(self, availabilityDidChange: .Available)
                        }
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
