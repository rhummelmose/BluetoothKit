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
