//
//  AppDelegate.swift
//  Cork
//
//  Created by David Bureš on 07.07.2022.
//

import AppKit
import DavidFoundation
import Foundation
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject
{
    @AppStorage("showInMenuBar") var showInMenuBar: Bool = false
    @AppStorage("startWithoutWindow") var startWithoutWindow: Bool = false

    @MainActor let appState: AppState = .init()

    func applicationWillFinishLaunching(_: Notification)
    {
        if startWithoutWindow
        {
            NSApp.setActivationPolicy(.accessory)
        }
        else
        {
            NSApp.setActivationPolicy(.regular)
        }
    }

    func applicationDidFinishLaunching(_: Notification)
    {
        if startWithoutWindow
        {
            for window in NSApp.windows
            {
                window.close()
            }
            
        }
        
        // Close the package preview window on systems older than macOS 15
        if #unavailable(macOS 15.0)
        {
            let windows: [NSWindow] = NSApp.windows
            let unwantedWindow = windows.map { window in
                return window.windowController
            }
            print("Windows: \(windows)")
            print("Unwanted window: \(unwantedWindow)")
        }
    }

    func applicationWillBecomeActive(_: Notification)
    {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationWillUnhide(_: Notification)
    {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool
    {
        if showInMenuBar
        {
            NSApp.setActivationPolicy(.accessory)
            return false
        }
        else
        {
            NSApp.setActivationPolicy(.regular)
            return true
        }
    }

    func applicationWillTerminate(_: Notification)
    {
        AppConstants.logger.debug("Will die...")
        do
        {
            try saveTaggedIDsToDisk(appState: appState)
        }
        catch let dataSavingError as NSError
        {
            AppConstants.logger.error("Failed while trying to save data to disk: \(dataSavingError, privacy: .public)")
        }
        AppConstants.logger.debug("Died")
    }

    func applicationDockMenu(_: NSApplication) -> NSMenu?
    {
        let menu: NSMenu = .init()
        menu.autoenablesItems = false

        let updatePackagesMenuItem: NSMenuItem = .init()
        updatePackagesMenuItem.action = #selector(appState.startUpdateProcessForLegacySelectors(_:))
        updatePackagesMenuItem.target = appState

        if appState.isCheckingForPackageUpdates
        {
            updatePackagesMenuItem.title = String(localized: "start-page.updates.loading")
            updatePackagesMenuItem.isEnabled = false
        }
        else if appState.isShowingUpdateSheet
        {
            updatePackagesMenuItem.title = String(localized: "update-packages.updating.updating")
            updatePackagesMenuItem.isEnabled = false
        }
        else
        {
            updatePackagesMenuItem.title = String(localized: "navigation.menu.packages.update")
            updatePackagesMenuItem.isEnabled = true
        }

        menu.addItem(updatePackagesMenuItem)

        return menu
    }
}
