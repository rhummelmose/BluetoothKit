//
//  BKCentral.swift
//  CustomerFacingDisplay
//
//  Created by Rasmus Taulborg Hummelmose on 17/08/15.
//  Copyright © 2015 Wallmob A/S. All rights reserved.
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
