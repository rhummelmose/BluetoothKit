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

internal class BKPeripheralStateMachine {
    
    // MARK: Enums
    
    internal enum Error: ErrorType {
        case Transitioning(currentState: State, validStates: [State])
    }
    
    internal enum State {
        case Initialized, Starting, Unavailable(cause: BKUnavailabilityCause), Available
    }
    
    internal enum Event {
        case Start, SetUnavailable(cause: BKUnavailabilityCause), SetAvailable, Stop
    }
    
    // MARK: Properties
    
    internal var state: State
    
    // MARK: Initialization
    
    internal init() {
        self.state = .Initialized
    }
    
    // MARK: Functions
    
    internal func handleEvent(event: Event) throws {
        switch event {
            case .Start: switch state {
                case .Initialized: state = .Starting
                default: throw Error.Transitioning(currentState: state, validStates: [ .Initialized ])
            }
            case .SetAvailable: switch state {
                case .Initialized: throw Error.Transitioning(currentState: state, validStates: [ .Starting, .Available, .Unavailable(cause: nil) ])
                default: state = .Available
            }
            case let .SetUnavailable(newCause): switch state {
                case .Initialized: throw Error.Transitioning(currentState: state, validStates: [ .Starting, .Available, .Unavailable(cause: nil) ])
                default: state = .Unavailable(cause: newCause)
            }
            case .Stop: switch state {
                case .Initialized: throw Error.Transitioning(currentState: state, validStates: [ .Starting, .Available, .Unavailable(cause: nil) ])
                default: state = .Initialized
            }
        }
    }
    
}
