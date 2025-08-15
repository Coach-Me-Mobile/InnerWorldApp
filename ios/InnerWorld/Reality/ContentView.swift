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

    var body: some View {
        ZStack {
            // RealityView is only available in iOS 18.0+
            if #available(iOS 18.0, *) {
                RealityView { content in

                    // Create a cube model
                    let model = Entity()
                    let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
                    let material = SimpleMaterial(color: .gray, roughness: 0.15, isMetallic: true)
                    model.components.set(ModelComponent(mesh: mesh, materials: [material]))
                    model.position = [0, 0.05, 0]

                    // Create horizontal plane anchor for the content
                    let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
                    anchor.addChild(model)

                    // Add the horizontal plane anchor to the scene
                    content.add(anchor)

                    content.camera = .spatialTracking

                }
                .edgesIgnoringSafeArea(.all)
            } else {
                // Fallback for iOS 16.0+ and Mac Catalyst
                VStack {
                    Spacer()
                    
                    Text("🔮 InnerWorld")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("AR Experience")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    Text("This feature requires iOS 18.0 or newer")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            
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

}

#Preview {
    ContentView()
}
