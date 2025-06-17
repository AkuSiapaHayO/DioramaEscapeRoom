import SwiftUI

struct ContentView: View {
    
    @StateObject private var controller = SceneKitController()
    
    var body: some View {
        SceneKitView(controller: controller)
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
