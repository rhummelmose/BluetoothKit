//
//  BKRemotePeer.swift
//  BluetoothKit
//
//  Created by Rasmus Taulborg Hummelmose on 12/05/2016.
//  Copyright © 2016 Rasmus Taulborg Hummelmose. All rights reserved.
//

import Foundation

public protocol BKRemotePeerDelegate: class {
    /**
     Called when the remote peer sent data.
     - parameter remotePeripheral: The remote peripheral that sent the data.
     - parameter data: The data it sent.
     */
    func remotePeer(remotePeer: BKRemotePeer, didSendArbitraryData data: NSData)
}

public func ==(lhs: BKRemotePeer, rhs: BKRemotePeer) -> Bool {
    return lhs.identifier.isEqual(rhs.identifier)
}

public class BKRemotePeer: Equatable {
    
    /// A unique identifier for the peer, derived from the underlying CBCentral or CBPeripheral object, or set manually.
    public let identifier: NSUUID
    
    public weak var delegate: BKRemotePeerDelegate?
    
    internal var configuration: BKConfiguration?
    private var data: NSMutableData?
    
    init(identifier: NSUUID) {
        self.identifier = identifier
    }
    
    internal var maximumUpdateValueLength: Int {
        return 20
    }
    
    internal func handleReceivedData(receivedData: NSData) {
        if receivedData.isEqualToData(configuration!.endOfDataMark) {
            if let finalData = data {
                delegate?.remotePeer(self, didSendArbitraryData: finalData)
            }
            data = nil
            return
        }
        if let existingData = data {
            existingData.appendData(receivedData)
            return
        }
        data = NSMutableData(data: receivedData)
    }
    
}
