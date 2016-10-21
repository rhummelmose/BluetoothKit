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

public func == (lhs: BKDiscoveriesChange, rhs: BKDiscoveriesChange) -> Bool {
    switch (lhs, rhs) {
        case (.insert(let lhsDiscovery), .insert(let rhsDiscovery)): return lhsDiscovery == rhsDiscovery || lhsDiscovery == nil || rhsDiscovery == nil
        case (.remove(let lhsDiscovery), .remove(let rhsDiscovery)): return lhsDiscovery == rhsDiscovery || lhsDiscovery == nil || rhsDiscovery == nil
        default: return false
    }
}

/**
    Change in available discoveries.
    - Insert: A new discovery.
    - Remove: A discovery has become unavailable.

    Cases without associated discoveries can be used to validate whether or not a change is and insert or a remove.
*/
public enum BKDiscoveriesChange: Equatable {

    case insert(discovery: BKDiscovery?)
    case remove(discovery: BKDiscovery?)

    /// The discovery associated with the change.
    public var discovery: BKDiscovery! {
        switch self {
            case .insert(let discovery): return discovery
            case .remove(let discovery): return discovery
        }
    }

}
