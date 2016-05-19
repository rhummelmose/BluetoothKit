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

import UIKit
import BluetoothKit

internal class AvailabilityView: UIView, BKAvailabilityObserver {

    // Properties

    private let offset = 10
    private let borderHeight = 0.33
    private let borderView = UIView()
    private let contentView = UIView()
    private let statusLabel = UILabel()

    // Initialization

    internal init() {
        super.init(frame: CGRect.zero)
        backgroundColor = Colors.lightGrey
        addSubview(borderView)
        addSubview(contentView)
        contentView.addSubview(statusLabel)
        statusLabel.attributedText = attributedStringForAvailability(nil)
        borderView.backgroundColor = Colors.darkGrey
        contentView.backgroundColor = UIColor.clearColor()
        statusLabel.textAlignment = NSTextAlignment.Center
        applyConstraints()
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    // MARK: Functions

    private func applyConstraints() {
        borderView.snp_makeConstraints { make in
            make.top.leading.trailing.equalTo(self)
            make.height.equalTo(borderHeight)
        }
        contentView.snp_makeConstraints { make in
            make.top.equalTo(borderView.snp_bottom)
            make.leading.trailing.bottom.equalTo(self)
        }
        statusLabel.snp_makeConstraints { make in
            make.top.leading.equalTo(contentView).offset(offset)
            make.bottom.trailing.equalTo(contentView).offset(-offset)
        }
    }

    private func attributedStringForAvailability(availability: BKAvailability?) -> NSAttributedString {
        let leadingText = "Bluetooth: "
        let trailingText = availabilityLabelTrailingTextForAvailability(availability)
        let string = leadingText + trailingText as NSString
        let attributedString = NSMutableAttributedString(string: string as String)
        attributedString.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFontOfSize(14), range: NSRange(location: 0, length: string.length))
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.blackColor(), range: string.rangeOfString(leadingText))
        if let availability = availability {
            switch availability {
            case .Available: attributedString.addAttribute(NSForegroundColorAttributeName, value: Colors.green, range: string.rangeOfString(trailingText))
            case .Unavailable: attributedString.addAttribute(NSForegroundColorAttributeName, value: Colors.red, range: string.rangeOfString(trailingText))
            }
        }
        return attributedString
    }

    private func availabilityLabelTrailingTextForAvailability(availability: BKAvailability?) -> String {
        if let availability = availability {
            switch availability {
            case .Available: return "Available"
            case .Unavailable(cause: .PoweredOff): return "Unavailable (Powered off)"
            case .Unavailable(cause: .Resetting): return "Unavailable (Resetting)"
            case .Unavailable(cause: .Unsupported): return "Unavailable (Unsupported)"
            case .Unavailable(cause: .Unauthorized): return "Unavailable (Unauthorized)"
            case .Unavailable(cause: .Any): return "Unavailable"
            }
        } else {
            return "Unknown"
        }
    }

    // MARK: BKAvailabilityObserver

    internal func availabilityObserver(availabilityObservable: BKAvailabilityObservable, availabilityDidChange availability: BKAvailability) {
        statusLabel.attributedText = attributedStringForAvailability(availability)
    }

    internal func availabilityObserver(availabilityObservable: BKAvailabilityObservable, unavailabilityCauseDidChange unavailabilityCause: BKUnavailabilityCause) {
        statusLabel.attributedText = attributedStringForAvailability(.Unavailable(cause: unavailabilityCause))
    }

}
