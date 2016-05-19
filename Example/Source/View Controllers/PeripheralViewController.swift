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
import SnapKit
import BluetoothKit
import CryptoSwift

internal class PeripheralViewController: UIViewController, AvailabilityViewController, BKPeripheralDelegate, LoggerDelegate, BKRemotePeerDelegate {

    // MARK: Properties

    internal var availabilityView = AvailabilityView()

    private let peripheral = BKPeripheral()
    private let logTextView = UITextView()
    private lazy var sendDataBarButtonItem: UIBarButtonItem! = { UIBarButtonItem(title: "Send Data", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(PeripheralViewController.sendData)) }()

    // MARK: UIViewController Life Cycle

    internal override func viewDidLoad() {
        navigationItem.title = "Peripheral"
        view.backgroundColor = UIColor.whiteColor()
        Logger.delegate = self
        applyAvailabilityView()
        logTextView.editable = false
        logTextView.alwaysBounceVertical = true
        view.addSubview(logTextView)
        applyConstraints()
        startPeripheral()
        sendDataBarButtonItem.enabled = false
        navigationItem.rightBarButtonItem = sendDataBarButtonItem
    }

    deinit {
        _ = try? peripheral.stop()
    }

    // MARK: Functions

    private func applyConstraints() {
        logTextView.snp_makeConstraints { make in
            make.top.equalTo(snp_topLayoutGuideBottom)
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(availabilityView.snp_top)
        }
    }

    private func startPeripheral() {
        do {
            peripheral.delegate = self
            peripheral.addAvailabilityObserver(self)
            let dataServiceUUID = NSUUID(UUIDString: "6E6B5C64-FAF7-40AE-9C21-D4933AF45B23")!
            let dataServiceCharacteristicUUID = NSUUID(UUIDString: "477A2967-1FAB-4DC5-920A-DEE5DE685A3D")!
            let localName = NSBundle.mainBundle().infoDictionary!["CFBundleName"] as? String
            let configuration = BKPeripheralConfiguration(dataServiceUUID: dataServiceUUID, dataServiceCharacteristicUUID: dataServiceCharacteristicUUID, localName: localName)
            try peripheral.startWithConfiguration(configuration)
            Logger.log("Awaiting connections from remote centrals")
        } catch let error {
            print("Error starting: \(error)")
        }
    }

    private func refreshControls() {
        sendDataBarButtonItem.enabled = peripheral.connectedRemoteCentrals.count > 0
    }

    // MARK: Target Actions

    @objc private func sendData() {
        let numberOfBytesToSend: Int = Int(arc4random_uniform(950) + 50)
        let data = NSData.dataWithNumberOfBytes(numberOfBytesToSend)
        Logger.log("Prepared \(numberOfBytesToSend) bytes with MD5 hash: \(data.md5().toHexString())")
        for remoteCentral in peripheral.connectedRemoteCentrals {
            Logger.log("Sending to \(remoteCentral)")
            peripheral.sendData(data, toRemotePeer: remoteCentral) { data, remoteCentral, error in
                guard error == nil else {
                    Logger.log("Failed sending to \(remoteCentral)")
                    return
                }
                Logger.log("Sent to \(remoteCentral)")
            }
        }
    }

    // MARK: BKPeripheralDelegate

    internal func peripheral(peripheral: BKPeripheral, remoteCentralDidConnect remoteCentral: BKRemoteCentral) {
        Logger.log("Remote central did connect: \(remoteCentral)")
        remoteCentral.delegate = self
        refreshControls()
    }

    internal func peripheral(peripheral: BKPeripheral, remoteCentralDidDisconnect remoteCentral: BKRemoteCentral) {
        Logger.log("Remote central did disconnect: \(remoteCentral)")
        refreshControls()
    }

    // MARK: BKRemotePeerDelegate

    func remotePeer(remotePeer: BKRemotePeer, didSendArbitraryData data: NSData) {
        Logger.log("Received data of length: \(data.length) with hash: \(data.md5().toHexString())")
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
