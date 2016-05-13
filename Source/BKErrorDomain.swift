//
//  BKErrorDomain.swift
//  BluetoothKit
//
//  Created by Rasmus Taulborg Hummelmose on 12/05/2016.
//  Copyright © 2016 Rasmus Taulborg Hummelmose. All rights reserved.
//

import Foundation

/**
    Errors that can occur when interacting with BluetoothKit.
    - InterruptedByUnavailability(cause): Will be returned if Bluetooth ie. is turned off while performing an action.
    - FailedToConnectDueToTimeout: The time out elapsed while attempting to connect to a peripheral.
    - RemotePeerNotConnected: The action failed because the remote peer attempted to interact with, was not connected.
    - InternalError(underlyingError): Will be returned if any of the internal or private classes returns an unhandled error.
 */
public enum BKError: ErrorType {
    case InterruptedByUnavailability(cause: BKUnavailabilityCause)
    case FailedToConnectDueToTimeout
    case RemotePeerNotConnected
    case InternalError(underlyingError: ErrorType?)
}
