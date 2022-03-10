//
//  TextEntryView.swift
//  dialog
//
//  Created by Reardon, Bart  on 23/7/21.
//

import SwiftUI

struct TextEntryView: View {
    
    @State var textFieldValue = Array(repeating: "", count: 64)
    //@State var textFieldValue = ""
    //var textFieldLabel = CLOptionText(OptionName: cloptions.textField)
    let textFieldLabels = appvars.textOptionsArray
    var textFieldPresent: Bool = false
    
    
    init() {
        if cloptions.textField.present {
            textFieldPresent = true
            for _ in textFieldLabels {
                textFieldValue.append(" ")
            }
        }
    }
    
    var body: some View {
        if textFieldPresent {
            VStack {
                ForEach(0..<textFieldLabels.count, id: \.self) {i in
                    HStack {
                        Spacer()
                        Text(String(textFieldLabels[i]).components(separatedBy: ",")[0])
                            .bold()
                            .font(.system(size: 15))
                            .frame(width: appvars.windowWidth/5, alignment: .leading)
                        Spacer()
                            .frame(width: 20)
                        HStack {
                            if textFieldLabels[i].lowercased().contains("password") {
                                SecureField("", text: $textFieldValue[i])
                            } else {
                                TextField("", text: $textFieldValue[i])
                            }
                        }
                        .frame(width: appvars.windowWidth/3, alignment: .trailing)
                        .onChange(of: textFieldValue[i], perform: { value in
                            //update appvars with the text that was entered. this will be printed to stdout on exit
                            appvars.textFieldText[i] = textFieldValue[i]
                        })
                        Spacer()
                    }
                }
            }//.frame(maxWidth: 500)
        }
    }
}

struct TextEntryView_Previews: PreviewProvider {
    static var previews: some View {
        TextEntryView()
    }
}
