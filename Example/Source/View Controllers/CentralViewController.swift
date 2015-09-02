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

internal class CentralViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, BKCentralDelegate, AvailabilityViewController, RemotePeripheralViewControllerDelegate {
    
    // MARK: Properties

    internal var availabilityView = AvailabilityView()
    
    private var activityIndicator: UIActivityIndicatorView {
        return activityIndicatorBarButtonItem.customView as! UIActivityIndicatorView
    }
    
    private let activityIndicatorBarButtonItem = UIBarButtonItem(customView: UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White))
    private let peripheralsTableView = UITableView()
    private var peripherals = [BKRemotePeripheral]()
    private let peripheralsTableViewCellIdentifier = "Peripheral Table View Cell Identifier"
    private let central = BKCentral()
    
    // MARK: UIViewController Life Cycle
    
    internal override func viewDidLoad() {
        view.backgroundColor = UIColor.whiteColor()
        activityIndicator.color = UIColor.blackColor()
        navigationItem.title = "Central"
        navigationItem.rightBarButtonItem = activityIndicatorBarButtonItem
        applyAvailabilityView()
        peripheralsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: peripheralsTableViewCellIdentifier)
        peripheralsTableView.dataSource = self
        peripheralsTableView.delegate = self
        view.addSubview(peripheralsTableView)
        applyConstraints()
        startCentral()
    }
    
    internal override func viewDidAppear(animated: Bool) {
        scan()
    }
    
    internal override func viewWillDisappear(animated: Bool) {
        central.interrupScan()
    }
    
    deinit {
        try! central.stop()
    }
    
    // MARK: Functions
    
    private func applyConstraints() {
        peripheralsTableView.snp_makeConstraints { make in
            make.top.equalTo(snp_topLayoutGuideBottom)
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(availabilityView.snp_top)
        }
    }
    
    private func startCentral() {
        do {
            central.delegate = self
            central.addAvailabilityObserver(self)
            try central.start()
        } catch let error {
            print("Error while starting: \(error)")
        }
    }
    
    private func scan() {
        central.scanContinuouslyWithChangeHandler({ changes, peripherals in
            let indexPathsToRemove = changes.filter({ $0 == .Remove(remotePeripheral: nil) }).map({ NSIndexPath(forRow: self.peripherals.indexOf($0.remotePeripheral)!, inSection: 0) })
            self.peripherals = peripherals
            let indexPathsToInsert = changes.filter({ $0 == .Insert(remotePeripheral: nil) }).map({ NSIndexPath(forRow: self.peripherals.indexOf($0.remotePeripheral)!, inSection: 0) })
            if !indexPathsToRemove.isEmpty {
                self.peripheralsTableView.deleteRowsAtIndexPaths(indexPathsToRemove, withRowAnimation: UITableViewRowAnimation.Automatic)
            }
            if !indexPathsToInsert.isEmpty {
                self.peripheralsTableView.insertRowsAtIndexPaths(indexPathsToInsert, withRowAnimation: UITableViewRowAnimation.Automatic)
            }
        }, stateHandler: { newState in
            if newState == .Scanning {
                self.activityIndicator.startAnimating()
                return
            } else if newState == .Stopped {
                self.peripherals.removeAll()
                self.peripheralsTableView.reloadData()
            }
            self.activityIndicator.stopAnimating()
        }, errorHandler: { error in
            Logger.log("Error from scanning: \(error)")
        })
    }
    
    // MARK: UITableViewDataSource
    
    internal func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    internal func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(peripheralsTableViewCellIdentifier, forIndexPath: indexPath)
        cell.textLabel?.text = peripherals[indexPath.row].name
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    internal func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.userInteractionEnabled = false
        central.connect(remotePeripheral: peripherals[indexPath.row]) { remotePeripheral, error in
            tableView.userInteractionEnabled = true
            guard error == nil else {
                print("Error connecting peripheral: \(error)")
                tableView.deselectRowAtIndexPath(indexPath, animated: true)
                return
            }
            let remotePeripheralViewController = RemotePeripheralViewController(remotePeripheral: remotePeripheral)
            remotePeripheralViewController.delegate = self
            self.navigationController?.pushViewController(remotePeripheralViewController, animated: true)
        }
    }
    
    // MARK: BKAvailabilityObserver
    
    internal func availabilityObserver(availabilityObservable: BKAvailabilityObservable, availabilityDidChange availability: BKAvailability) {
        availabilityView.availabilityObserver(availabilityObservable, availabilityDidChange: availability)
        if availability == .Available {
            scan()
        } else {
            central.interrupScan()
        }
    }
    
    // MARK: BKCentralDelegate
    
    internal func central(central: BKCentral, remotePeripheralDidDisconnect remotePeripheral: BKRemotePeripheral) {
        Logger.log("Remote peripheral did disconnect: \(remotePeripheral)")
        self.navigationController?.popToViewController(self, animated: true)
    }
    
    // MARK: RemotePeripheralViewControllerDelegate
    
    internal func remotePeripheralViewControllerWillDismiss(remotePeripheralViewController: RemotePeripheralViewController) {
        do {
            try central.disconnectRemotePeripheral(remotePeripheralViewController.remotePeripheral)
        } catch let error {
            Logger.log("Error disconnecting remote peripheral: \(error)")
        }
    }
    
}
