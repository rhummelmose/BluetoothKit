//
//  BKSendDataTask.swift
//  BluetoothKit
//
//  Created by Rasmus Taulborg Hummelmose on 25/08/15.
//  Copyright © 2015 Wallmob A/S. All rights reserved.
//

import Foundation

internal func ==(lhs: BKSendDataTask, rhs: BKSendDataTask) -> Bool {
    return lhs.destination == rhs.destination && lhs.data.isEqualToData(rhs.data)
}

internal class BKSendDataTask: Equatable {
    
    internal let data: NSData
    internal let destination: BKRemoteCentral
    internal let completionHandler: ((data: NSData, remoteCentral: BKRemoteCentral, error: BKPeripheral.Error?) -> Void)?
    internal var offset = 0
    
    internal var maximumPayloadLength: Int {
        return destination.central.maximumUpdateValueLength
    }
    
    internal var lengthOfRemainingData: Int {
        return data.length - (offset + 1)
    }
    
    internal var sentAllData: Bool {
        return lengthOfRemainingData == 0
    }
    
    internal var rangeForNextPayload: NSRange {
        let lenghtOfNextPayload = maximumPayloadLength <= lengthOfRemainingData ? maximumPayloadLength : lengthOfRemainingData
        return NSMakeRange(offset, lenghtOfNextPayload)
    }
    
    internal var nextPayload: NSData {
        return data.subdataWithRange(rangeForNextPayload)
    }
    
    internal init(data: NSData, destination: BKRemoteCentral, completionHandler: ((data: NSData, remoteCentral: BKRemoteCentral, error: BKPeripheral.Error?) -> Void)?) {
        self.data = data
        self.destination = destination
        self.completionHandler = completionHandler
    }
    
}
