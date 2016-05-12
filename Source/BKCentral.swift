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

/**
    The class used to take the Bluetooth LE central role. The central discovers remote peripherals by scanning
    and connects to them. When a connection is established the central can receive data from the remote peripheral.
*/
public class BKCentral: BKCBCentralManagerStateDelegate, BKConnectionPoolDelegate, BKAvailabilityObservable {
    
    // MARK: Type Aliases
    
    public typealias ScanProgressHandler = ((newDiscoveries: [BKDiscovery]) -> Void)
    public typealias ScanCompletionHandler = ((result: [BKDiscovery]?, error: Error?) -> Void)
    public typealias ContinuousScanChangeHandler = ((changes: [BKDiscoveriesChange], discoveries: [BKDiscovery]) -> Void)
    public typealias ContinuousScanStateHandler = ((newState: ContinuousScanState) -> Void)
    public typealias ContinuousScanErrorHandler = ((error: Error) -> Void)
    public typealias ConnectCompletionHandler = ((remotePeripheral: BKRemotePeripheral, error: Error?) -> Void)
    
    // MARK: Enums
    
    /**
        Errors that can occur when interacting with BKCentral objects.
        - InterruptedByUnavailability(cause): Will be returned if Bluetooth ie. is turned off while performing an action.
        - FailedToConnectDueToTimeout: The time out elapsed while attempting to connect to a peripheral.
        - InternalError(underlyingError): Will be returned if any of the internal or private classes returns an unhandled error.
    */
    public enum Error: ErrorType {
        case InterruptedByUnavailability(cause: BKUnavailabilityCause)
        case FailedToConnectDueToTimeout
        case InternalError(underlyingError: ErrorType?)
    }
    
    /**
        Possible states returned by the ContinuousScanStateHandler.
        - Stopped: The scan has come to a complete stop and won't start again by triggered manually.
        - Scanning: The scan is currently active.
        - Waiting: The scan is on hold due while waiting for the in-between delay to expire, after which it will start again.
    */
    public enum ContinuousScanState {
        case Stopped
        case Scanning
        case Waiting
    }
    
    // MARK: Properties
    
    /// Bluetooth LE availability, derived from the underlying CBCentralManager.
    public var availability: BKAvailability? {
        if let centralManager = _centralManager {
            return BKAvailability(centralManagerState: centralManager.state)
        } else {
            return nil
        }
    }
    
    /// All currently connected remote peripherals.
    public var connectedRemotePeripherals: [BKRemotePeripheral] {
        return connectionPool.connectedRemotePeripherals
    }
    
    /// The configuration the BKCentral object was started with.
    public var configuration: BKConfiguration? {
        return _configuration
    }
    
    /// The delegate of the BKCentral object.
    public weak var delegate: BKCentralDelegate?
    
    /// Current availability observers.
    public var availabilityObservers = [BKWeakAvailabilityObserver]()
    
    private var centralManager: CBCentralManager? {
        return _centralManager
    }
    
    private let scanner = BKScanner()
    private let connectionPool = BKConnectionPool()
    private var _configuration: BKConfiguration?
    private var continuousScanner: BKContinousScanner!
    private var centralManagerDelegate: BKCBCentralManagerDelegateProxy!
    private var stateMachine: BKCentralStateMachine!
    private var _centralManager: CBCentralManager!
    
    // MARK: Initialization
    
    public init() {
        centralManagerDelegate = BKCBCentralManagerDelegateProxy(stateDelegate: self, discoveryDelegate: scanner, connectionDelegate: connectionPool)
        stateMachine = BKCentralStateMachine()
        connectionPool.delegate = self;
        continuousScanner = BKContinousScanner(scanner: scanner)
    }
    
    // MARK: Public Functions
    
    /**
        Start the BKCentral object with a configuration.
        - parameter configuration: The configuration defining which UUIDs to use when discovering peripherals.
        - throws: Throws an InternalError if the BKCentral object is already started.
    */
    public func startWithConfiguration(configuration: BKConfiguration) throws {
        do {
            try stateMachine.handleEvent(.Start)
            _configuration = configuration
            _centralManager = CBCentralManager(delegate: centralManagerDelegate, queue: nil, options: nil)
            scanner.configuration = configuration
            scanner.centralManager = centralManager
            connectionPool.centralManager = centralManager
        } catch let error {
            throw Error.InternalError(underlyingError: error)
        }
    }
    
    /**
        Scan for peripherals for a limited duration of time.
        - parameter duration: The number of seconds to scan for (defaults to 3).
        - parameter progressHandler: A progress handler allowing you to react immediately when a peripheral is discovered during a scan.
        - parameter completionHandler: A completion handler allowing you to react on the full result of discovered peripherals or an error if one occured.
    */
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
    
    /**
        Scan for peripherals for a limited duration of time continuously with an in-between delay.
        - parameter changeHandler: A change handler allowing you to react to changes in "maintained" discovered peripherals.
        - parameter stateHandler: A state handler allowing you to react when the scanner is started, waiting and stopped.
        - parameter duration: The number of seconds to scan for (defaults to 3).
        - parameter inBetweenDelay: The number of seconds to wait for, in-between scans (defaults to 3).
        - parameter errorHandler: An error handler allowing you to react when an error occurs. For now this is also called when the scan is manually interrupted.
    */
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
    
    /**
        Interrupts the active scan session if present.
    */
    public func interrupScan() {
        continuousScanner.interruptScan()
        scanner.interruptScan()
    }
    
    /**
        Connect to a remote peripheral.
        - parameter timeout: The number of seconds the connection attempt should continue for before failing.
        - parameter remotePeripheral: The remote peripheral to connect to.
        - parameter completionHandler: A completion handler allowing you to react when the connection attempt succeeded or failed.
    */
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
    
    /**
        Disconnects a connected peripheral.
        - parameter remotePeripheral: The peripheral to disconnect.
        - throws: Throws an InternalError if the remote peripheral is not currently connected.
    */
    public func disconnectRemotePeripheral(remotePeripheral: BKRemotePeripheral) throws {
        do {
            try connectionPool.disconnectRemotePeripheral(remotePeripheral)
        } catch let error {
            throw Error.InternalError(underlyingError: error)
        }
    }
    
    /**
        Stops the BKCentral object.
        - throws: Throws an InternalError if the BKCentral object isn't already started.
    */
    public func stop() throws {
        do {
            try stateMachine.handleEvent(.Stop)
            interrupScan()
            connectionPool.reset()
            _configuration = nil
            _centralManager = nil
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
    
    internal func connectionPool(connectionPool: BKConnectionPool, remotePeripheralDidDisconnect remotePeripheral: BKRemotePeripheral) {
        delegate?.central(self, remotePeripheralDidDisconnect: remotePeripheral)
    }
    
}
