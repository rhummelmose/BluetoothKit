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
import CryptoSwift

internal protocol RemotePeripheralViewControllerDelegate: class {
    func remotePeripheralViewControllerWillDismiss(remotePeripheralViewController: RemotePeripheralViewController)
}

internal class RemotePeripheralViewController: UIViewController, BKRemotePeripheralDelegate, BKRemotePeerDelegate, LoggerDelegate {

    // MARK: Properties

    internal weak var delegate: RemotePeripheralViewControllerDelegate?
    internal let central: BKCentral
    internal let remotePeripheral: BKRemotePeripheral

    private let logTextView = UITextView()
    private lazy var sendDataBarButtonItem: UIBarButtonItem! = { UIBarButtonItem(title: "Send Data", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(RemotePeripheralViewController.sendData)) }()

    // MARK: Initialization

    internal init(central: BKCentral, remotePeripheral: BKRemotePeripheral) {
        self.central = central
        self.remotePeripheral = remotePeripheral
        super.init(nibName: nil, bundle: nil)
        remotePeripheral.delegate = self
        remotePeripheral.peripheralDelegate = self
    }

    internal required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    // MARK: UIViewController Life Cycle

    internal override func viewDidLoad() {
        navigationItem.title = remotePeripheral.name
        navigationItem.rightBarButtonItem = sendDataBarButtonItem
        Logger.delegate = self
        view.addSubview(logTextView)
        view.backgroundColor = UIColor.whiteColor()
        #if os(iOS)
            logTextView.editable = false
        #endif
        logTextView.alwaysBounceVertical = true
        applyConstraints()
        Logger.log("Awaiting data from peripheral")
    }

    internal override func viewWillDisappear(animated: Bool) {
        delegate?.remotePeripheralViewControllerWillDismiss(self)
    }

    // MARK: Functions

    internal func applyConstraints() {
        logTextView.snp_makeConstraints { make in
            make.top.leading.trailing.bottom.equalTo(view)
        }
    }

    // MARK: BKRemotePeripheralDelegate

    internal func remotePeripheral(remotePeripheral: BKRemotePeripheral, didUpdateName name: String) {
        navigationItem.title = name
        Logger.log("Name change: \(name)")
    }

    internal func remotePeer(remotePeer: BKRemotePeer, didSendArbitraryData data: NSData) {
        Logger.log("Received data of length: \(data.length) with hash: \(data.md5().toHexString())")
    }

    // MARK: Target Actions

    @objc private func sendData() {
        let numberOfBytesToSend: Int = Int(arc4random_uniform(950) + 50)
        let data = NSData.dataWithNumberOfBytes(numberOfBytesToSend)
        Logger.log("Prepared \(numberOfBytesToSend) bytes with MD5 hash: \(data.md5().toHexString())")
        Logger.log("Sending to \(remotePeripheral)")
        central.sendData(data, toRemotePeer: remotePeripheral) { data, remotePeripheral, error in
            guard error == nil else {
                Logger.log("Failed sending to \(remotePeripheral)")
                return
            }
            Logger.log("Sent to \(remotePeripheral)")
        }
    }

    // MARK: LoggerDelegate

    internal func loggerDidLogString(string: String) {
        if logTextView.text.characters.count > 0 {
            logTextView.text = logTextView.text.stringByAppendingString("\n" + string)
        } else {
            logTextView.text = string
        }
        logTextView.scrollRangeToVisible(NSRange(location: logTextView.text.characters.count - 1, length: 1))
    }
}
