//
//  BKService.swift
//  CustomerFacingDisplay
//
//  Created by Rasmus Taulborg Hummelmose on 24/08/15.
//  Copyright © 2015 Wallmob A/S. All rights reserved.
//

import CoreBluetooth

internal enum BKService: String {
    
    case DataTransferService = "BA4EE259-A10D-4D7A-AF57-53741F24DEDF"
    
    internal var identifier: CBUUID {
        return CBUUID(string: self.rawValue)
    }
    
    internal enum Characteristic: String {
        case Data = "F96C5F17-3B1A-4FA1-A904-FD076825F048"
        var identifier: CBUUID {
            return CBUUID(string: self.rawValue)
        }
    }
    
    internal var characteristics: [Characteristic] {
        switch self {
            case .DataTransferService: return [ Characteristic.Data ]
        }
    }
    
    internal var characteristicIdentifiers: [CBUUID] {
        return characteristics.map { characteristic -> CBUUID in
            return CBUUID(string: characteristic.rawValue)
        }
    }
    
    internal static var endOfDataMark: NSData {
        return "EOM".dataUsingEncoding(NSUTF8StringEncoding)!
    }
}
