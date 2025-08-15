//
//  ContentView.swift
//  InnerWorld
//
//  Created by Trevor Slaton on 8/12/25.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var arViewContainer = ARViewContainer()
    @State private var currentYaw: Float = 0
    @State private var currentPitch: Float = 0
    @State private var lastDragLocation: CGSize = .zero
    
    var body: some View {
        ZStack {
            RealityKitViewWrapper(arViewContainer: arViewContainer)
                .edgesIgnoringSafeArea(.all)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let delta = CGSize(
                                width: value.translation.width - lastDragLocation.width,
                                height: value.translation.height - lastDragLocation.height
                            )
                            updateCameraRotation(delta: delta)
                            lastDragLocation = value.translation
                        }
                        .onEnded { _ in
                            lastDragLocation = .zero
                        }
                )
            
            VStack {
                Spacer()
                Button("Sign Out") { session.signOut() }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 50)
            }
        }
    }
    
    private func updateCameraRotation(delta: CGSize) {
        let sensitivity: Float = 0.01
        
        // Calculate rotation deltas (inverted for natural feel)
        let deltaYaw = Float(delta.width) * sensitivity
        let deltaPitch = Float(delta.height) * sensitivity
        
        // Update accumulated rotation
        currentYaw += deltaYaw
        currentPitch += deltaPitch
        
        // Clamp pitch to prevent over-rotation (~70 degrees up/down)
        currentPitch = min(max(currentPitch, -1.2), 1.2)
        
        // Apply rotation using the container's method
        arViewContainer.updateRotation(yaw: currentYaw, pitch: currentPitch)
    }

}

#Preview {
    ContentView()
}
