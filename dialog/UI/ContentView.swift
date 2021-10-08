//
//  ContentView.swift
//  dialog
//
//  Created by Bart Reardon on 9/3/21.
//

import SwiftUI



struct ContentView: View {
    init() {
        if cloptions.debug.present {
            print("Window Height = \(appvars.windowHeight): Window Width = \(appvars.windowWidth)")
        }
    }

    var bannerAdjustment       = CGFloat(5)
    var waterMarkFill          = String("")
        
    var body: some View {
                
        ZStack {
            if cloptions.watermarkImage.present {
                    watermarkView(imagePath: cloptions.watermarkImage.value, opacity: Double(cloptions.watermarkAlpha.value), position: cloptions.watermarkPosition.value, scale: cloptions.watermarkFill.value)
            }
        
            // this stack controls the main view. Consists of a VStack containing all the content, and a HStack positioned at the bottom of the display area
            VStack {
                if cloptions.bannerImage.present {
                    BannerImageView(imagePath: cloptions.bannerImage.value)
                        .border(appvars.debugBorderColour, width: 2)
                }

                // Dialog title
                TitleView()
                    .border(appvars.debugBorderColour, width: 2)
                    .offset(y: 10) // shift the title down a notch
                
                // Horozontal Line
                Divider()
                    .frame(width: appvars.windowWidth*appvars.horozontalLineScale, height: 2)
                            
                // Dialog content including message and image if visible
                DialogView()
                
                Spacer()
                
                // Buttons
                HStack() {
                    if cloptions.infoButtonOption.present {
                        MoreInfoButton()
                        if !cloptions.timerBar.present {
                            Spacer()
                        }
                    }
                    if cloptions.timerBar.present {
                        progressBarView(progressSteps: NumberFormatter().number(from: cloptions.timerBar.value) as? CGFloat, visible: !cloptions.hideTimerBar.present)
                            .frame(alignment: .bottom)
                    }
                    if (cloptions.timerBar.present && cloptions.button1TextOption.present) || (!cloptions.timerBar.present) {
                        ButtonView() // contains both button 1 and button 2
                    }
                }
                //.frame(alignment: .bottom)
                .padding(.leading, 15)
                .padding(.trailing, 15)
                .padding(.bottom, 15)
                .border(appvars.debugBorderColour, width: 2)
 
            }
            
            // Window Setings (pinched from Nudge https://github.com/macadmins/nudge/blob/main/Nudge/UI/ContentView.swift#L19)
            HostingWindowFinder {window in
                window?.standardWindowButton(.closeButton)?.isHidden = true //hides the red close button
                window?.standardWindowButton(.miniaturizeButton)?.isHidden = true //hides the yellow miniaturize button
                window?.standardWindowButton(.zoomButton)?.isHidden = true //this removes the green zoom button
                window?.isMovable = appvars.windowIsMoveable
                if appvars.windowOnTop {
                    window?.level = .floating
                } else {
                    window?.level = .normal
                }
                NSApp.activate(ignoringOtherApps: true) // bring to forefront upon launch
            }
                
        }
        .edgesIgnoringSafeArea(.all)
        .hostingWindowPosition(vertical: appvars.windowPositionVertical, horizontal: appvars.windowPositionHorozontal)  
    }
    

}

