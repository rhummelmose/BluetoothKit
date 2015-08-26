//
//  BKCentralStateMachine.swift
//  CustomerFacingDisplay
//
//  Created by Rasmus Taulborg Hummelmose on 20/08/15.
//  Copyright © 2015 Wallmob A/S. All rights reserved.
//

import Foundation

internal class BKCentralStateMachine {
    
    // MARK: Enums
    
    internal enum Error: ErrorType {
        case Transitioning(currentState: State, validStates: [State])
    }
    
    internal enum State {
        case Initialized, Starting, Unavailable(cause: BKUnavailabilityCause), Available, Scanning
    }
    
    internal enum Event {
        case Start, SetUnavailable(cause: BKUnavailabilityCause), SetAvailable, Scan, Connect
    }
    
    // MARK: Stored Properties
    
    internal var state: State
    
    // MARK: Initialization
    
    internal init() {
        self.state = .Initialized
    }
    
    // MARK: State Machine
    
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
            case .Scan: switch state {
                case .Available: state = .Scanning
                default: throw Error.Transitioning(currentState: state, validStates: [ .Available ])
            }
            case .Connect: switch state {
                case .Available, .Scanning: break
                default: throw Error.Transitioning(currentState: state, validStates: [ .Available, .Scanning ])
            }
        }
    }
    
}
