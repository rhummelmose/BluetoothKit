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

    func central(_ central: BKCentral, remotePeripheralDidDisconnect remotePeripheral: BKRemotePeripheral)
}

/**
    The class used to take the Bluetooth LE central role. The central discovers remote peripherals by scanning
    and connects to them. When a connection is established the central can receive data from the remote peripheral.
*/

public class BKCentral: BKPeer, BKCBCentralManagerStateDelegate, BKConnectionPoolDelegate, BKAvailabilityObservable {

    // MARK: Type Aliases

    public typealias ScanProgressHandler = ((_ newDiscoveries: [BKDiscovery]) -> Void)
    public typealias ScanCompletionHandler = ((_ result: [BKDiscovery]?, _ error: BKError?) -> Void)
    public typealias ContinuousScanChangeHandler = ((_ changes: [BKDiscoveriesChange], _ discoveries: [BKDiscovery]) -> Void)
    public typealias ContinuousScanStateHandler = ((_ newState: ContinuousScanState) -> Void)
    public typealias ContinuousScanErrorHandler = ((_ error: BKError) -> Void)
    public typealias ConnectCompletionHandler = ((_ remotePeripheral: BKRemotePeripheral, _ error: BKError?) -> Void)

    // MARK: Enums

    /**
        Possible states returned by the ContinuousScanStateHandler.
        - Stopped: The scan has come to a complete stop and won't start again by triggered manually.
        - Scanning: The scan is currently active.
        - Waiting: The scan is on hold due while waiting for the in-between delay to expire, after which it will start again.
    */
    public enum ContinuousScanState {
        case stopped
        case scanning
        case waiting
    }

    // MARK: Properties

    /// Bluetooth LE availability, derived from the underlying CBCentralManager.
    public var availability: BKAvailability? {
        guard let centralManager = _centralManager else {
            return nil
        }
            #if os(iOS) || os(tvOS)
                if #available(tvOS 10.0, iOS 10.0, *) {
                    return BKAvailability(managerState: centralManager.state)
                } else {
                    return BKAvailability(centralManagerState: centralManager.centralManagerState)
                }
            #else
                return BKAvailability(centralManagerState: centralManager.state)
            #endif

    }

    /// All currently connected remote peripherals.
    public var connectedRemotePeripherals: [BKRemotePeripheral] {
        return connectionPool.connectedRemotePeripherals
    }

    override public var configuration: BKConfiguration? {
        return _configuration
    }

    /// The delegate of the BKCentral object.
    public weak var delegate: BKCentralDelegate?

    /// Current availability observers.
    public var availabilityObservers = [BKWeakAvailabilityObserver]()

    internal override var connectedRemotePeers: [BKRemotePeer] {
        get {
            return connectedRemotePeripherals
        }
        set {
            connectionPool.connectedRemotePeripherals = newValue.flatMap({
                guard let remotePeripheral = $0 as? BKRemotePeripheral else {
                    return nil
                }
                return remotePeripheral
            })
        }
    }

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

    public override init() {
        super.init()
        centralManagerDelegate = BKCBCentralManagerDelegateProxy(stateDelegate: self, discoveryDelegate: scanner, connectionDelegate: connectionPool)
        stateMachine = BKCentralStateMachine()
        connectionPool.delegate = self
        continuousScanner = BKContinousScanner(scanner: scanner)
    }

    // MARK: Public Functions

    /**
        Start the BKCentral object with a configuration.
        - parameter configuration: The configuration defining which UUIDs to use when discovering peripherals.
        - throws: Throws an InternalError if the BKCentral object is already started.
    */
    public func startWithConfiguration(_ configuration: BKConfiguration) throws {
        do {
            try stateMachine.handleEvent(.start)
            _configuration = configuration
            _centralManager = CBCentralManager(delegate: centralManagerDelegate, queue: nil, options: nil)
            scanner.configuration = configuration
            scanner.centralManager = centralManager
            connectionPool.centralManager = centralManager
        } catch let error {
            throw BKError.internalError(underlyingError: error)
        }
    }

    /**
        Scan for peripherals for a limited duration of time.
        - parameter duration: The number of seconds to scan for (defaults to 3).
        - parameter progressHandler: A progress handler allowing you to react immediately when a peripheral is discovered during a scan.
        - parameter completionHandler: A completion handler allowing you to react on the full result of discovered peripherals or an error if one occured.
    */
    public func scanWithDuration(_ duration: TimeInterval = 3, progressHandler: ScanProgressHandler?, completionHandler: ScanCompletionHandler?) {
        do {
            try stateMachine.handleEvent(.scan)
            try scanner.scanWithDuration(duration, progressHandler: progressHandler) { result, error in
                var returnError: BKError?
                if error == nil {
                    _ = try? self.stateMachine.handleEvent(.setAvailable)
                } else {
                    returnError = .internalError(underlyingError: error)
                }
                completionHandler?(result, returnError)
            }
        } catch let error {
            completionHandler?(nil, .internalError(underlyingError: error))
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

    public func scanContinuouslyWithChangeHandler(_ changeHandler: @escaping ContinuousScanChangeHandler, stateHandler: ContinuousScanStateHandler?, duration: TimeInterval = 3, inBetweenDelay: TimeInterval = 3, errorHandler: ContinuousScanErrorHandler?) {
        do {
            try stateMachine.handleEvent(.scan)
            continuousScanner.scanContinuouslyWithChangeHandler(changeHandler, stateHandler: { newState in
                if newState == .stopped && self.availability == .available {
                    _ = try? self.stateMachine.handleEvent(.setAvailable)
                }
                stateHandler?(newState)
            }, duration: duration, inBetweenDelay: inBetweenDelay, errorHandler: { error in
                errorHandler?(.internalError(underlyingError: error))
            })
        } catch let error {
            errorHandler?(.internalError(underlyingError: error))
        }
    }

    /**
        Interrupts the active scan session if present.
    */
    public func interruptScan() {
        continuousScanner.interruptScan()
        scanner.interruptScan()
    }

    /**
        Connect to a remote peripheral.
        - parameter timeout: The number of seconds the connection attempt should continue for before failing.
        - parameter remotePeripheral: The remote peripheral to connect to.
        - parameter completionHandler: A completion handler allowing you to react when the connection attempt succeeded or failed.
    */
    public func connect(_ timeout: TimeInterval = 3, remotePeripheral: BKRemotePeripheral, completionHandler: @escaping ConnectCompletionHandler) {
        do {
            try stateMachine.handleEvent(.connect)
            try connectionPool.connectWithTimeout(timeout, remotePeripheral: remotePeripheral) { remotePeripheral, error in
                var returnError: BKError?
                if error == nil {
                    _ = try? self.stateMachine.handleEvent(.setAvailable)
                } else {
                    returnError = .internalError(underlyingError: error)
                }
                completionHandler(remotePeripheral, returnError)
            }
        } catch let error {
            completionHandler(remotePeripheral, .internalError(underlyingError: error))
            return
        }
    }

    /**
        Disconnects a connected peripheral.
        - parameter remotePeripheral: The peripheral to disconnect.
        - throws: Throws an InternalError if the remote peripheral is not currently connected.
    */
    public func disconnectRemotePeripheral(_ remotePeripheral: BKRemotePeripheral) throws {
        do {
            try connectionPool.disconnectRemotePeripheral(remotePeripheral)
        } catch let error {
            throw BKError.internalError(underlyingError: error)
        }
    }

    /**
        Stops the BKCentral object.
        - throws: Throws an InternalError if the BKCentral object isn't already started.
    */
    public func stop() throws {
        do {
            try stateMachine.handleEvent(.stop)
            interruptScan()
            connectionPool.reset()
            _configuration = nil
            _centralManager = nil
        } catch let error {
            throw BKError.internalError(underlyingError: error)
        }
    }

    /**
        Retrieves a previously-scanned peripheral for direct connection.
        - parameter remoteUUID: The UUID of the remote peripheral to look for
        - return: optional remote peripheral if found
     */
    public func retrieveRemotePeripheralWithUUID (remoteUUID: UUID) -> BKRemotePeripheral? {
        guard let peripherals = retrieveRemotePeripheralsWithUUIDs(remoteUUIDs: [remoteUUID]) else {
            return nil
        }
        guard peripherals.count > 0 else {
            return nil
        }
        return peripherals[0]
    }

    /**
        Retrieves an array of previously-scanned peripherals for direct connection.
        - parameter remoteUUIDs: An array of UUIDs of remote peripherals to look for
        - return: optional array of found remote peripherals
     */
    public func retrieveRemotePeripheralsWithUUIDs (remoteUUIDs: [UUID]) -> [BKRemotePeripheral]? {
        if let centralManager = _centralManager {
            let peripherals = centralManager.retrievePeripherals(withIdentifiers: remoteUUIDs)
            guard peripherals.count > 0 else {
                return nil
            }

            var remotePeripherals: [BKRemotePeripheral] = []

            for peripheral in peripherals {
                let remotePeripheral = BKRemotePeripheral(identifier: peripheral.identifier, peripheral: peripheral)
                remotePeripheral.configuration = configuration
                remotePeripherals.append(remotePeripheral)
            }
            return remotePeripherals
        }
        return nil
    }

    // MARK: Internal Functions

    internal func setUnavailable(_ cause: BKUnavailabilityCause, oldCause: BKUnavailabilityCause?) {
        scanner.interruptScan()
        connectionPool.reset()
        if oldCause == nil {
            for availabilityObserver in availabilityObservers {
                availabilityObserver.availabilityObserver?.availabilityObserver(self, availabilityDidChange: .unavailable(cause: cause))
            }
        } else if oldCause != nil && oldCause != cause {
            for availabilityObserver in availabilityObservers {
                availabilityObserver.availabilityObserver?.availabilityObserver(self, unavailabilityCauseDidChange: cause)
            }
        }
    }

    internal override func sendData(_ data: Data, toRemotePeer remotePeer: BKRemotePeer) -> Bool {
        guard let remotePeripheral = remotePeer as? BKRemotePeripheral,
                let peripheral = remotePeripheral.peripheral,
                let characteristic = remotePeripheral.characteristicData else {
            return false
        }
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        return true
    }

    // MARK: BKCBCentralManagerStateDelegate


    internal func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .unknown, .resetting:
                break
            case .unsupported, .unauthorized, .poweredOff:
                let newCause: BKUnavailabilityCause
                #if os(iOS) || os(tvOS)
                    if #available(iOS 10.0, tvOS 10.0, *) {
                        newCause = BKUnavailabilityCause(managerState: central.state)
                    } else {
                        newCause = BKUnavailabilityCause(centralManagerState: central.centralManagerState)
                    }
                #else
                    newCause = BKUnavailabilityCause(centralManagerState: central.state)
                #endif
                switch stateMachine.state {
                    case let .unavailable(cause):
                        let oldCause = cause
                        _ = try? stateMachine.handleEvent(.setUnavailable(cause: newCause))
                        setUnavailable(oldCause, oldCause: newCause)
                    default:
                        _ = try? stateMachine.handleEvent(.setUnavailable(cause: newCause))
                        setUnavailable(newCause, oldCause: nil)
                }

            case .poweredOn:
                let state = stateMachine.state
                _ = try? stateMachine.handleEvent(.setAvailable)
                switch state {
                    case .starting, .unavailable:
                        for availabilityObserver in availabilityObservers {
                            availabilityObserver.availabilityObserver?.availabilityObserver(self, availabilityDidChange: .available)
                        }
                    default:
                        break
                }
        }
    }

    // MARK: BKConnectionPoolDelegate

    internal func connectionPool(_ connectionPool: BKConnectionPool, remotePeripheralDidDisconnect remotePeripheral: BKRemotePeripheral) {
        delegate?.central(self, remotePeripheralDidDisconnect: remotePeripheral)
    }

}
