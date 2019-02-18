//
//  BKService.swift
//  BluetoothKit iOS
//
//  Created by Camila on 2/18/19.
//  Copyright © 2019 Rasmus Taulborg Hummelmose. All rights reserved.
//

import Foundation
import CoreBluetooth

public class BKService {
    /// The CBUUID of the service. This should be unique to your applications.
    public let serviceCBUUID: CBUUID

    /// The CBUUID of the characteristics used to send data.
    public var writableCharacteristics: [CBUUID]

    /// The CBUUID of the characteristics used to recieve data.
    public var readableCharacteristics: [CBUUID]

    public var allCharacteristics: [CBUUID] {
        return readableCharacteristics + writableCharacteristics
    }

    // MARK: Initialization

    public init(serviceCBUUID: CBUUID,
                writableCharacteristics: [CBUUID],
                readableCharacteristics: [CBUUID]) {
        self.serviceCBUUID = serviceCBUUID
        self.writableCharacteristics = writableCharacteristics
        self.readableCharacteristics = readableCharacteristics
    }
}
