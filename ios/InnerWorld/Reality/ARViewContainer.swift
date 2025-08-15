//
//  ARViewContainer.swift
//  InnerWorld
//
//  Manages ARView and scene rotation without tilt
//

import SwiftUI
import RealityKit

class ARViewContainer: ObservableObject {
    var arView: ARView?
    var sceneAnchor: AnchorEntity?
    
    func setupView() -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(.black)
        self.arView = view
        
        loadInnerWorldScene(in: view)
        return view
    }
    
    private func loadInnerWorldScene(in view: ARView) {
        do {
            let projectPath = "/Users/home/Documents/projects/gauntlet/bounty/inner/ios/InnerWorldApp/ios/InnerWorld/InnerWorldRoom/Sources/InnerWorldRoom/InnerWorldRoom.rkassets/Scene.usda"
            let sceneURL = URL(fileURLWithPath: projectPath)
            
            if FileManager.default.fileExists(atPath: projectPath) {
                print("Loading scene from: \(sceneURL)")
                
                // Load the scene entity
                let loadedEntity = try Entity.load(contentsOf: sceneURL)
                
                // Keep scene at full size so we're inside it
                loadedEntity.scale = [1.0, 1.0, 1.0]
                
                // Create an anchor at world origin
                let anchor = AnchorEntity(world: .zero)
                anchor.addChild(loadedEntity)
                
                // Position scene so camera is at eye level in room center
                loadedEntity.position = [0, -1.7, -1]
                
                // Add the anchor to the scene
                view.scene.addAnchor(anchor)
                
                // Store the anchor reference
                self.sceneAnchor = anchor
                
                print("Successfully loaded InnerWorldRoom scene")
            } else {
                print("Scene file not found at: \(projectPath)")
                createTestScene(in: view)
            }
        } catch {
            print("Error loading scene: \(error)")
            createTestScene(in: view)
        }
    }
    
    private func createTestScene(in view: ARView) {
        let mesh = MeshResource.generateBox(size: 1)
        let material = SimpleMaterial(color: .systemBlue, roughness: 0.5, isMetallic: true)
        let model = ModelEntity(mesh: mesh, materials: [material])
        model.position = [0, 0, -2]
        
        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(model)
        view.scene.addAnchor(anchor)
        self.sceneAnchor = anchor
        
        print("Created test scene")
    }
    
    func updateRotation(yaw: Float, pitch: Float) {
        guard let anchor = sceneAnchor else { return }
        
        // CRITICAL: Apply rotations in correct order to prevent tilt
        // First create yaw rotation around world Y axis
        let yawQuat = simd_quatf(angle: -yaw, axis: SIMD3<Float>(0, 1, 0))
        
        // Then create pitch rotation around world X axis
        let pitchQuat = simd_quatf(angle: -pitch, axis: SIMD3<Float>(1, 0, 0))
        
        // Combine in correct order: pitch * yaw prevents roll
        // This keeps the horizon level
        anchor.transform.rotation = pitchQuat * yawQuat
    }
}