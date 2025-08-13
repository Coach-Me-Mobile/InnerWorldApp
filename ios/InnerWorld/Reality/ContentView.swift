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
