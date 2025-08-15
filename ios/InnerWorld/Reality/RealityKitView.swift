//
//  RealityKitView.swift
//  InnerWorld
//
//  Created for InnerWorld RealityKit integration
//

import SwiftUI
import RealityKit
import ARKit

struct RealityKitView: UIViewRepresentable {
    @Binding var arView: ARView?
    @Binding var sceneAnchor: AnchorEntity?
    
    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        
        // Set a solid background color for non-AR mode
        view.environment.background = .color(.black)
        
        // Load the scene synchronously to ensure it's ready
        loadInnerWorldScene(in: view)
        
        return view
    }
    
    private func loadInnerWorldScene(in view: ARView) {
        do {
            // Load the Scene.usda file directly from the file system during development
            let projectPath = "/Users/home/Documents/projects/gauntlet/bounty/inner/ios/InnerWorldApp/ios/InnerWorld/InnerWorldRoom.rkassets/Scene.usda"
            let sceneURL = URL(fileURLWithPath: projectPath)
            
            if FileManager.default.fileExists(atPath: projectPath) {
                print("Loading scene from: \(sceneURL)")
                
                // Load the scene entity
                let loadedEntity = try Entity.load(contentsOf: sceneURL)
                
                // Don't scale the scene - keep it at full size so we're inside it
                loadedEntity.scale = [1.0, 1.0, 1.0]
                
                // Create an anchor at world origin that we'll rotate
                let anchor = AnchorEntity(world: .zero)
                anchor.addChild(loadedEntity)
                
                // Position the scene so camera is at room center at eye level
                // Move the scene down so camera is at standing height (about 1.7 meters)
                loadedEntity.position = [0, -1.7, -1]  // Adjust Y for eye height, Z to center in room
                
                // Add the anchor to the scene
                view.scene.addAnchor(anchor)
                
                // Store references after a small delay to avoid SwiftUI state update warnings
                DispatchQueue.main.async {
                    self.arView = view
                    self.sceneAnchor = anchor
                }
                
                print("Successfully loaded InnerWorldRoom scene")
            } else {
                print("Scene file not found at: \(projectPath)")
                // Fallback to test scene
                createTestScene(in: view)
            }
        } catch {
            print("Error loading scene: \(error)")
            createTestScene(in: view)
        }
    }
    
    private func createTestScene(in view: ARView) {
        // Create a simple test scene to verify RealityKit is working
        let mesh = MeshResource.generateBox(size: 1)
        let material = SimpleMaterial(color: .systemBlue, roughness: 0.5, isMetallic: true)
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.position = [0, 0, -2]
        
        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(model)
        
        view.scene.addAnchor(anchor)
        
        // Store the anchor reference after a small delay
        DispatchQueue.main.async {
            self.arView = view
            self.sceneAnchor = anchor
        }
        
        print("Created test scene - RealityKit assets may not be properly included in bundle")
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Updates handled through bindings
    }
}