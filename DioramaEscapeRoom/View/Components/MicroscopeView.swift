//
//  MicroscopeView.swift
//  DioramaEscapeRoom
//
//  Created by Derend Marvel Hanson Prionggo on 22/06/25.
//

import SwiftUI

struct MicroscopeView: View {
    let sceneFile: String
    @State var isUVLightOn: Bool = false
    
    var body: some View {
        ZStack {
            Color.black
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            HStack {
                Spacer()
                VStack{
                    Inventory(level: sceneFile, nodeName: "UV_Flashlight", isFlashlightOn: $isUVLightOn)

                    // In Inventory, pass a binding
                    Inventory(level: sceneFile, nodeName: "Golden_Key", isFlashlightOn: $isUVLightOn)
                    
                    Inventory(level: sceneFile, nodeName: "Clue_color", isFlashlightOn: $isUVLightOn)
                }
            }
            .padding(24)
        }
        
    }
}

#Preview {
    MicroscopeView(sceneFile: "Science Lab Updated.scn")
}
