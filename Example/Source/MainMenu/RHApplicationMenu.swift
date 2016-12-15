//
//  RHApplicationMenu.swift
//  BKExample
//
//  Created by Rasmus H. Hummelmose on 25/11/2016.
//  Copyright © 2016 Rasmus Høhndorf Hummelmose. All rights reserved.
//

import Cocoa

public class RHApplicationMenu: NSMenu {
    
    // MARK: Properties
    
    public var aboutMenuItem: NSMenuItem?
    public var preferencesMenuItem: NSMenuItem?
    public var servicesMenuItem: NSMenuItem?
    public var hideMenuItem: NSMenuItem?
    public var hideOthersMenuItem: NSMenuItem?
    public var showAllMenuItem: NSMenuItem?
    public var quitMenuItem: NSMenuItem?
    
    // MARK: Initialization
    
    public convenience init() {
        let applicationName = NSRunningApplication.current().localizedName ?? ""
        self.init(title: applicationName)
    }
    
    public override init(title: String) {
        super.init(title: title)
        quitMenuItem = buildQuitMenuItem()
        addItem(quitMenuItem!)
    }
    
    required public init(coder decoder: NSCoder) {
        fatalError("Interface builder... really?")
    }
    
    // MARK: Menu Items
    
    private func buildQuitMenuItem() -> NSMenuItem {
        var title = NSLocalizedString("Quit", comment: "Quit as shown in the application menu.")
        
        if let applicationName = NSRunningApplication.current().localizedName {
            title += " \(applicationName)"
        }
        let quitMenuItem = NSMenuItem(title: title, action: NSSelectorFromString("terminate:"), keyEquivalent: "\(NSOptionsKey)Q")
        return quitMenuItem
    }
    
}
