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
        contentView.backgroundColor = UIColor.clear
        statusLabel.textAlignment = NSTextAlignment.center
        applyConstraints()
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    // MARK: Functions

    private func applyConstraints() {
        borderView.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(self)
            make.height.equalTo(borderHeight)
        }
        contentView.snp.makeConstraints { make in
            make.top.equalTo(borderView.snp.bottom)
            make.leading.trailing.bottom.equalTo(self)
        }
        statusLabel.snp.makeConstraints { make in
            make.top.leading.equalTo(contentView).offset(offset)
            make.bottom.trailing.equalTo(contentView).offset(-offset)
        }
    }

    private func attributedStringForAvailability(_ availability: BKAvailability?) -> NSAttributedString {
        let leadingText = "Bluetooth: "
        let trailingText = availabilityLabelTrailingTextForAvailability(availability)
        let string = leadingText + trailingText as NSString
        let attributedString = NSMutableAttributedString(string: string as String)
        attributedString.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFont(ofSize: 14), range: NSRange(location: 0, length: string.length))
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.black, range: string.range(of: leadingText))
        if let availability = availability {
            switch availability {
            case .available: attributedString.addAttribute(NSForegroundColorAttributeName, value: Colors.green, range: string.range(of: trailingText))
            case .unavailable: attributedString.addAttribute(NSForegroundColorAttributeName, value: Colors.red, range: string.range(of: trailingText))
            }
        }
        return attributedString
    }

    private func availabilityLabelTrailingTextForAvailability(_ availability: BKAvailability?) -> String {
        if let availability = availability {
            switch availability {
            case .available: return "Available"
            case .unavailable(cause: .poweredOff): return "Unavailable (Powered off)"
            case .unavailable(cause: .resetting): return "Unavailable (Resetting)"
            case .unavailable(cause: .unsupported): return "Unavailable (Unsupported)"
            case .unavailable(cause: .unauthorized): return "Unavailable (Unauthorized)"
            case .unavailable(cause: .any): return "Unavailable"
            }
        } else {
            return "Unknown"
        }
    }

    // MARK: BKAvailabilityObserver

    internal func availabilityObserver(_ availabilityObservable: BKAvailabilityObservable, availabilityDidChange availability: BKAvailability) {
        statusLabel.attributedText = attributedStringForAvailability(availability)
    }

    internal func availabilityObserver(_ availabilityObservable: BKAvailabilityObservable, unavailabilityCauseDidChange unavailabilityCause: BKUnavailabilityCause) {
        statusLabel.attributedText = attributedStringForAvailability(.unavailable(cause: unavailabilityCause))
    }

}
