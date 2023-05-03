//
//  dialogApp.swift
//  dialog
//
//  Created by Bart Reardon on 9/3/21.
//

import SwiftUI
import Combine
import UserNotifications
import OSLog

import SystemConfiguration

var background = BlurWindowController()

// Log Stuff
let bundleID = Bundle.main.bundleIdentifier ?? "au.bartreardon.dialog"
let osLog = OSLog(subsystem: bundleID, category: "main")

// AppDelegate and extension used for notifications
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        return completionHandler([.list, .sound])
    }
}


@available(OSX 11.0, *)
@main
struct dialogApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @ObservedObject var observedData : DialogUpdatableContent
    
    @State private var cancellables = Set<AnyCancellable>()
    
    func monitorVisibility(window: NSWindow) {
        window.publisher(for: \.isVisible)
            .dropFirst()  // we know: the first value is not interesting
            .sink(receiveValue: { isVisible in
                if isVisible {
                    placeWindow(window)
                }
            })
            .store(in: &cancellables)
    }
    
    init () {
        
                                writeLog("Dialog Launched")
        
        // Ensure the singleton NSApplication exists.
        // required for correct determination of screen dimentions for the screen in use in multi screen scenarios
        _ = NSApplication.shared
        
        if let screen = NSScreen.main {
            let rect = screen.frame
            appvars.screenHeight = rect.size.height
            appvars.screenWidth = rect.size.width
        }
        
        // get all the command line option values
        processCLOptionValues()
                
        // check for notification
        if appArguments.notification.present {
            var notificationIcon = ""
            if appArguments.iconOption.present {
                notificationIcon = appArguments.iconOption.value
            }
            sendNotification(title: appArguments.titleOption.value, subtitle: appArguments.subTitleOption.value, message: appArguments.messageOption.value, image: notificationIcon)
            usleep(100000)
            quitDialog(exitCode: 0)
        }
        
        
        // check for jamfhelper mode
        if appArguments.jamfHelperMode.present {
                                    writeLog("converting jh to dialog")
            convertFromJamfHelperSyntax()
        }
        
        // process remaining command line options
        processCLOptions()
                        
        appvars.overlayShadow = 1
                
        appvars.titleHeight = appvars.titleHeight * appvars.scaleFactor
        appvars.windowWidth = appvars.windowWidth * appvars.scaleFactor
        appvars.windowHeight = appvars.windowHeight * appvars.scaleFactor
        appvars.iconWidth = appvars.iconWidth * appvars.scaleFactor
        appvars.iconHeight = appvars.iconHeight * appvars.scaleFactor
        
        if appArguments.miniMode.present {
            appvars.windowWidth = 540
            appvars.windowHeight = 128
        }
                
        //check debug mode and print info
        if appArguments.debug.present {
                                    writeLog("debug options presented. dialog state sent to stdout")
            appvars.debugMode = true
            appvars.debugBorderColour = Color.green
            
            print("Window Height = \(appvars.windowHeight): Window Width = \(appvars.windowWidth)")
            
            print("\nApplication State Variables")
            let mirrored_appvars = Mirror(reflecting: appvars)
            for (_, attr) in mirrored_appvars.children.enumerated() {
                if let propertyName = attr.label as String? {
                print("  \(propertyName) = \(attr.value)")
              }
            }
            print("\nApplication Command Line Options")
            let mirrored_appArguments = Mirror(reflecting: appArguments)
            for (_, attr) in mirrored_appArguments.children.enumerated() {
                if let propertyName = attr.label as String? {
                print("  \(propertyName) = \(attr.value)")
              }
            }
        }
                                writeLog("width: \(appvars.windowWidth), height: \(appvars.windowHeight)")
        
        observedData = DialogUpdatableContent()
        
        if appArguments.fullScreenWindow.present {
            FullscreenView(observedData: observedData).showFullScreen()
        }
        
        if appArguments.constructionKit.present {
            ConstructionKitView(observedDialogContent: observedData).showConstructionKit()
            observedData.args.movableWindow.present = true
        }
        
        // bring to front on launch
        NSApp.activate(ignoringOtherApps: true)
    }
    
    var body: some Scene {

        WindowGroup {
            ZStack {
                WindowAccessor {window in
                    window?.standardWindowButton(.closeButton)?.isHidden = true //hides the red close button
                    window?.standardWindowButton(.miniaturizeButton)?.isHidden = true //hides the yellow miniaturize button
                    window?.standardWindowButton(.zoomButton)?.isHidden = true //this removes the green zoom button
                    window?.isMovable = observedData.args.movableWindow.present
                    window?.isMovableByWindowBackground = true
                    window?.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
                    
                    // Set window level
                    if observedData.args.forceOnTop.present || observedData.args.blurScreen.present {
                        window?.level = .floating
                    } else {
                        window?.level = .normal
                    }
                    
                    // display a blur screen window on all screens.
                    if observedData.args.blurScreen.present && !appArguments.fullScreenWindow.present {
                        let screens = NSScreen.screens
                        for (index, screen) in screens.enumerated() {
                            observedData.blurredScreen.append(BlurWindowController())
                            allScreens = screen
                            observedData.blurredScreen[index].close()
                            observedData.blurredScreen[index].loadWindow()
                            observedData.blurredScreen[index].showWindow(self)
                        }
                        NSApp.windows[0].level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow) + 1))
                    } else {
                        background.close()
                    }
                    
                    if observedData.args.forceOnTop.present || observedData.args.blurScreen.present {
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
                .frame(width: 0, height: 0) //ensures WindowAccessor isn't taking up any real estate
                if !appArguments.notification.present {
                    if appArguments.miniMode.present {
                        MiniView(observedDialogContent: observedData)
                            .frame(width: observedData.windowWidth, height: observedData.windowHeight)
                    } else {
                        ContentView(observedDialogContent: observedData)
                            .frame(width: observedData.windowWidth, height: observedData.windowHeight)
                            .sheet(isPresented: $observedData.showSheet, content: {
                                ErrorView(observedContent: observedData)
                            })
                    }
                }
            }
            // Monitor window visibility, process position on screen before rendering.
            .background(WindowAccessor { newWindow in
                    if let newWindow = newWindow {
                        monitorVisibility(window: newWindow)
                        observedData.mainWindow = newWindow
                    } else {
                        // window closed: release all references
                        observedData.mainWindow = nil
                        self.cancellables.removeAll()
                    }
                })
             
        }
        // Hide Title Bar
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizabilityContentSize()
    }

    
}


