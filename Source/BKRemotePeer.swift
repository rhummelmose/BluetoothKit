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
    func remotePeer(_ remotePeer: BKRemotePeer, didSendArbitraryData data: Data)
}

public func ==(lhs: BKRemotePeer, rhs: BKRemotePeer) -> Bool {
    return (lhs.identifier == rhs.identifier)
}

public class BKRemotePeer: Equatable {
    
    /// A unique identifier for the peer, derived from the underlying CBCentral or CBPeripheral object, or set manually.
    public let identifier: UUID
    
    public weak var delegate: BKRemotePeerDelegate?
    
    internal var configuration: BKConfiguration?
    private var data: NSMutableData?
    
    init(identifier: UUID) {
        self.identifier = identifier
    }
    
    internal var maximumUpdateValueLength: Int {
        return 20
    }
    
    internal func handleReceivedData(_ receivedData: Data) {
        if receivedData == configuration!.endOfDataMark {
            if let finalData = data {
                delegate?.remotePeer(self, didSendArbitraryData: finalData as Data)
            }
            data = nil
            return
        }
        if let existingData = data {
            existingData.append(receivedData)
            return
        }
        data = NSData(data: receivedData) as! NSMutableData
    }
    
}
