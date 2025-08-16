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
    @Published var interactableObjectNearby: String? = nil
    @Published var lastTappedObject: String? = nil
    @Published var isZoomedToBookshelf: Bool = false
    @Published var debugMode: Bool = false
    @Published var isRecording: Bool = false
    @Published var capturedPositions: [String] = []
    @Published var currentDeskPosition: String = ""
    
    private var originalCameraPosition: SIMD3<Float> = .zero
    private var originalCameraRotation: simd_quatf = simd_quatf()
    
    func setupView() -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(.black)
        self.arView = view
        
        loadInnerWorldScene(in: view)
        setupGestures(in: view)
        return view
    }
    
    private func loadInnerWorldScene(in view: ARView) {
        do {
            // Try multiple approaches to find the scene file
            var sceneURL: URL?
            
            // Approach 1: Look in the main bundle for the copied resource
            sceneURL = Bundle.main.url(
                forResource: "Scene",
                withExtension: "usda",
                subdirectory: "InnerWorldRoom/Sources/InnerWorldRoom/InnerWorldRoom.rkassets"
            )
            
            // Approach 2: Try without the full path structure
            if sceneURL == nil {
                sceneURL = Bundle.main.url(
                    forResource: "Scene",
                    withExtension: "usda",
                    subdirectory: "InnerWorldRoom.rkassets"
                )
            }
            
            // Approach 3: Look for the file in the app bundle's resource directory
            if sceneURL == nil {
                let bundlePath = Bundle.main.bundlePath
                let possiblePaths = [
                    "\(bundlePath)/InnerWorldRoom/Sources/InnerWorldRoom/InnerWorldRoom.rkassets/Scene.usda",
                    "\(bundlePath)/InnerWorldRoom.rkassets/Scene.usda",
                    "\(bundlePath)/Scene.usda"
                ]
                
                for path in possiblePaths {
                    if FileManager.default.fileExists(atPath: path) {
                        sceneURL = URL(fileURLWithPath: path)
                        break
                    }
                }
            }
            
            guard let finalSceneURL = sceneURL else {
                print("Scene.usda not found in bundle")
                print("Bundle path: \(Bundle.main.bundlePath)")
                print("Searched locations:")
                print("  - InnerWorldRoom/Sources/InnerWorldRoom/InnerWorldRoom.rkassets/")
                print("  - InnerWorldRoom.rkassets/")
                print("  - Root bundle directory")
                createTestScene(in: view)
                return
            }
            
            print("Loading scene from: \(finalSceneURL)")
            
            // Load the scene entity
            let loadedEntity = try Entity.load(contentsOf: finalSceneURL)
            
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
        
        // Check proximity to interactive objects
        checkProximityToInteractables()
    }
    
    private func setupGestures(in view: ARView) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let view = arView else { return }
        
        let location = gesture.location(in: view)
        let hitResults = view.hitTest(location)
        
        for result in hitResults {
            if let entity = result.entity as? ModelEntity {
                // Check if this is the bigshelf or its parent
                if isInteractableObject(entity) {
                    handleObjectInteraction(entity)
                    break
                }
            }
        }
    }
    
    private func isInteractableObject(_ entity: Entity) -> Bool {
        // Check entity and its parents for interactive object names
        var current: Entity? = entity
        while current != nil {
            if current?.name == "bigshelf" || current?.name.contains("bigshelf") == true ||
               current?.name == "chest_open" || current?.name.contains("chest") == true ||
               current?.name == "desk" || current?.name.contains("desk") == true {
                return true
            }
            current = current?.parent
        }
        return false
    }
    
    private func handleObjectInteraction(_ entity: Entity) {
        print("Interacted with: \(entity.name)")
        lastTappedObject = entity.name
        
        // Zoom to bookshelf
        zoomToBookshelf()
        
        // Add visual feedback
        if let modelEntity = entity as? ModelEntity {
            // Create a quick flash effect
            let originalMaterials = modelEntity.model?.materials ?? []
            
            // Create highlight material
            var highlightMaterial = SimpleMaterial()
            highlightMaterial.color = .init(tint: .yellow, texture: nil)
            highlightMaterial.metallic = 0.8
            highlightMaterial.roughness = 0.2
            
            // Apply highlight
            modelEntity.model?.materials = [highlightMaterial]
            
            // Restore original after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                modelEntity.model?.materials = originalMaterials
            }
        }
    }
    
    private func checkProximityToInteractables() {
        guard let arView = arView,
              let anchor = sceneAnchor else { return }
        
        // Get camera info
        let cameraTransform = arView.cameraTransform
        let cameraPosition = cameraTransform.translation
        let cameraForward = cameraTransform.matrix.columns.2
        
        // Check for bigshelf
        if let bigshelf = findEntity(named: "bigshelf", in: anchor) {
            let shelfWorldPosition = bigshelf.position(relativeTo: nil)
            let distance = simd_distance(cameraPosition, shelfWorldPosition)
            let directionToShelf = simd_normalize(shelfWorldPosition - cameraPosition)
            let dotProduct = -simd_dot(SIMD3<Float>(cameraForward.x, cameraForward.y, cameraForward.z), directionToShelf)
            
            // Debug logging
            print("Bookshelf detection - Distance: \(distance), DotProduct: \(dotProduct)")
            print("Camera pos: \(cameraPosition), Shelf pos: \(shelfWorldPosition)")
            
            // Bigshelf detection box
            let isLikelyBigshelf = (
                shelfWorldPosition.x >= -2.2 && shelfWorldPosition.x <= 2.1 &&
                shelfWorldPosition.y >= -3.1 && shelfWorldPosition.y <= 3.1 &&
                shelfWorldPosition.z >= -4.3 && shelfWorldPosition.z <= -2.8 &&
                distance >= 5.7 && distance <= 6.3
            )
            
            if isLikelyBigshelf && dotProduct > 0.84 {
                DispatchQueue.main.async { [weak self] in
                    if self?.interactableObjectNearby != "bigshelf" {
                        print("Showing interaction hint for bookshelf")
                    }
                    self?.interactableObjectNearby = "bigshelf"
                }
                return
            }
        }
        
        // Check for chest_open (Mini Games)
        if let chest = findEntity(named: "chest_open", in: anchor) {
            let chestWorldPosition = chest.position(relativeTo: nil)
            let distance = simd_distance(cameraPosition, chestWorldPosition)
            let directionToChest = simd_normalize(chestWorldPosition - cameraPosition)
            let dotProduct = -simd_dot(SIMD3<Float>(cameraForward.x, cameraForward.y, cameraForward.z), directionToChest)
            
            // Debug logging for chest
            print("Chest detection - Distance: \(distance), DotProduct: \(dotProduct)")
            print("Camera pos: \(cameraPosition), Chest pos: \(chestWorldPosition)")
            
            // Chest detection box - CORRECTED based on actual console output
            // The chest is actually at around (-0.106, -0.418 to -5.16, -5.167)
            // This is very different from the earlier positions provided
            // Using wider ranges to catch rotation variations
            
            let isLikelyChest = (
                chestWorldPosition.x >= -2.5 && chestWorldPosition.x <= 2.5 &&  // Wide X range for rotation
                chestWorldPosition.y >= -6.0 && chestWorldPosition.y <= 1.0 &&  // Y can go quite negative
                chestWorldPosition.z >= -6.0 && chestWorldPosition.z <= -4.0 &&  // Z is around -5
                distance >= 6.5 && distance <= 8.0  // Distance around 7-7.5 meters
            )
            
            print("Chest check - X in range: \(chestWorldPosition.x >= -2.5 && chestWorldPosition.x <= 2.5)")
            print("Chest check - Y in range: \(chestWorldPosition.y >= -6.0 && chestWorldPosition.y <= 1.0)")
            print("Chest check - Z in range: \(chestWorldPosition.z >= -6.0 && chestWorldPosition.z <= -4.0)")
            print("Chest check - Distance in range: \(distance >= 6.5 && distance <= 8.0)")
            print("Chest check - Dot product ok: \(dotProduct > -0.1)")
            print("Chest check - Is likely chest: \(isLikelyChest)")
            
            if isLikelyChest && dotProduct > -0.1 {  // Very low threshold since min was -0.033
                DispatchQueue.main.async { [weak self] in
                    if self?.interactableObjectNearby != "chest_open" {
                        print("Showing interaction hint for mini games")
                    }
                    self?.interactableObjectNearby = "chest_open"
                }
                return
            }
        } else {
            print("Warning: Could not find chest_open entity in scene")
        }
        
        // Check for desk
        if let desk = findEntity(named: "desk", in: anchor) {
            let deskWorldPosition = desk.position(relativeTo: nil)
            let distance = simd_distance(cameraPosition, deskWorldPosition)
            let directionToDesk = simd_normalize(deskWorldPosition - cameraPosition)
            let dotProduct = -simd_dot(SIMD3<Float>(cameraForward.x, cameraForward.y, cameraForward.z), directionToDesk)
            
            // Desk detection box based on captured positions
            let isLikelyDesk = (
                deskWorldPosition.x >= -2.1 && deskWorldPosition.x <= 2.0 &&
                deskWorldPosition.y >= -3.8 && deskWorldPosition.y <= 3.4 &&
                deskWorldPosition.z >= -5.4 && deskWorldPosition.z <= -3.8 &&
                distance >= 6.9 && distance <= 7.4
            )
            
            if isLikelyDesk && dotProduct > 0.84 {
                DispatchQueue.main.async { [weak self] in
                    if self?.interactableObjectNearby != "desk" {
                        print("Showing interaction hint for desk")
                    }
                    self?.interactableObjectNearby = "desk"
                }
                return
            }
        }
        
        // Check for desk (debug mode)
        if debugMode {
            if let desk = findEntity(named: "desk", in: anchor) {
                let deskWorldPosition = desk.position(relativeTo: nil)
                let distance = simd_distance(cameraPosition, deskWorldPosition)
                let directionToDesk = simd_normalize(deskWorldPosition - cameraPosition)
                let dotProduct = -simd_dot(SIMD3<Float>(cameraForward.x, cameraForward.y, cameraForward.z), directionToDesk)
                
                // Format position data
                let positionData = String(format: "Desk - Dist: %.2f, Dot: %.3f, Pos: (%.2f, %.2f, %.2f)",
                                         distance, dotProduct,
                                         deskWorldPosition.x, deskWorldPosition.y, deskWorldPosition.z)
                
                // Update UI on main thread
                DispatchQueue.main.async { [weak self] in
                    self?.currentDeskPosition = positionData
                    
                    // If recording, capture this position
                    if self?.isRecording == true {
                        let isDuplicate = self?.capturedPositions.contains(where: { pos in
                            // Avoid duplicate positions (within small threshold)
                            pos.contains(String(format: "%.1f", deskWorldPosition.x)) &&
                            pos.contains(String(format: "%.1f", deskWorldPosition.y)) &&
                            pos.contains(String(format: "%.1f", deskWorldPosition.z))
                        }) ?? false
                        
                        if !isDuplicate {
                            self?.capturedPositions.append(positionData)
                            print("Captured position: \(positionData)")
                        }
                    }
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.currentDeskPosition = "Desk not found in scene"
                }
            }
        }
        
        // No interactive object nearby
        DispatchQueue.main.async { [weak self] in
            if self?.interactableObjectNearby != nil {
                print("Hiding interaction hint")
                self?.interactableObjectNearby = nil
            }
        }
    }
    
    func clearCapturedPositions() {
        capturedPositions.removeAll()
    }
    
    func exportPositions() -> String {
        return capturedPositions.joined(separator: "\n")
    }
    
    private func findEntity(named name: String, in entity: Entity) -> Entity? {
        // Check exact match first
        if entity.name == name {
            return entity
        }
        
        // Then check children for exact match
        for child in entity.children {
            if let found = findEntity(named: name, in: child) {
                return found
            }
        }
        
        return nil
    }
    
    func zoomToBookshelf() {
        guard let anchor = sceneAnchor,
              let bigshelf = findEntity(named: "bigshelf", in: anchor) else { return }
        
        // Store original position
        originalCameraPosition = anchor.position
        originalCameraRotation = anchor.transform.rotation
        
        // Calculate position to view bookshelf
        let shelfPosition = bigshelf.position(relativeTo: anchor)
        
        // Move scene so bookshelf is centered and closer
        // Adjust these values to get the right framing
        let targetPosition = SIMD3<Float>(
            -shelfPosition.x * 0.8,  // Center horizontally
            -1.7 - shelfPosition.y * 0.5,  // Maintain eye level
            1.5  // Move closer to bookshelf
        )
        
        // Animate the transition
        withAnimation(.easeInOut(duration: 0.8)) {
            anchor.position = targetPosition
            anchor.transform.rotation = simd_quatf()  // Reset rotation
            isZoomedToBookshelf = true
        }
        
        // Hide interaction hint when zoomed
        interactableObjectNearby = nil
    }
    
    func returnToOriginalView() {
        guard let anchor = sceneAnchor else { return }
        
        // Animate back to original position
        withAnimation(.easeInOut(duration: 0.6)) {
            anchor.position = originalCameraPosition
            anchor.transform.rotation = originalCameraRotation
            isZoomedToBookshelf = false
        }
    }
}