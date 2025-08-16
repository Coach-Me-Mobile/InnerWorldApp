//
//  ARViewContainer.swift
//  InnerWorld
//
//  Manages ARView and scene rotation without tilt
//

import SwiftUI
import RealityKit
import simd

enum InteractableObject {
    case bookshelf
    case desk
    case chest
    
    var entityName: String {
        switch self {
        case .bookshelf: return "bigshelf"
        case .desk: return "desk"
        case .chest: return "chest_open"
        }
    }
}

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
    @Published var currentAnchorPosition: String = ""
    @Published var cameraState = CameraState()
    
    private var originalCameraPosition: SIMD3<Float> = .zero
    private var originalCameraRotation: simd_quatf = simd_quatf()
    private var objectOriginalPositions: [Entity: SIMD3<Float>] = [:]
    
    // Hardcoded camera positions from capture
    private let centerRoomPosition = CameraPosition(
        translation: SIMD3<Float>(0, 0, 0),  // Anchor stays at origin, scene is positioned
        rotation: simd_quatf()
    )
    
    // The actual scene offset for the room
    private let sceneOffset = SIMD3<Float>(0, -1.7, -1)
    
    private let bookshelfCameraPosition = CameraPosition(
        translation: SIMD3<Float>(-0.505, -0.076, 1.246),
        rotation: simd_quatf(vector: SIMD4<Float>(0.020, -0.130, -0.003, 0.991))
    )
    
    private let deskCameraPosition = CameraPosition(
        translation: SIMD3<Float>(0.865, -4.960, 1.373),
        rotation: simd_quatf(vector: SIMD4<Float>(0.191, 0.764, 0.558, 0.261))
    )
    
    private let chestCameraPosition = CameraPosition(
        translation: SIMD3<Float>(-0.145, -1.794, 4.364),
        rotation: simd_quatf(vector: SIMD4<Float>(-0.146, 0.791, 0.208, -0.556))
    )
    
    var hasAnyCapturedPositions: Bool {
        return cameraState.bookshelfPosition != nil ||
               cameraState.deskPosition != nil ||
               cameraState.chestPosition != nil
    }
    
    func setupView() -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(.black)
        self.arView = view
        
        // Initialize camera state with hardcoded positions
        cameraState.bookshelfPosition = bookshelfCameraPosition
        cameraState.deskPosition = deskCameraPosition
        cameraState.chestPosition = chestCameraPosition
        
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
            // The scene itself is offset, not the anchor
            loadedEntity.position = sceneOffset
            
            // Start anchor higher and rotated for intro animation
            var startTransform = Transform()
            startTransform.translation = SIMD3<Float>(0, 2.5, 0) // Start 2.5 units higher
            startTransform.rotation = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))
            anchor.transform = startTransform
            
            // Add the anchor to the scene
            view.scene.addAnchor(anchor)
            
            // Store the anchor reference
            self.sceneAnchor = anchor
            
            // Setup objects for falling animation
            setupObjectsForFallingAnimation(in: loadedEntity)
            
            // Perform intro animation (camera spiral + objects falling)
            performIntroAnimation(anchor: anchor, sceneEntity: loadedEntity)
            
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
        
        // Don't allow manual rotation during animation
        if cameraState.isAnimating { return }
        
        // CRITICAL: Apply rotations in correct order to prevent tilt
        // First create yaw rotation around world Y axis
        let yawQuat = simd_quatf(angle: -yaw, axis: SIMD3<Float>(0, 1, 0))
        
        // Then create pitch rotation around world X axis
        let pitchQuat = simd_quatf(angle: -pitch, axis: SIMD3<Float>(1, 0, 0))
        
        // Combine in correct order: pitch * yaw prevents roll
        // This keeps the horizon level
        anchor.transform.rotation = pitchQuat * yawQuat
        
        // Update position display
        updateCurrentPositionDisplay()
        
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
        
        // Determine which object was tapped and animate to it
        if entity.name.contains("shelf") {
            animateToObject(.bookshelf)
        } else if entity.name.contains("desk") {
            animateToObject(.desk)
        } else if entity.name.contains("chest") {
            animateToObject(.chest)
        } else {
            // Fallback to old zoom behavior
            zoomToBookshelf()
        }
        
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
        
        // Extract just the yaw (horizontal rotation) from current rotation
        let currentRotation = anchor.transform.rotation
        let yawOnlyRotation = extractYawRotation(from: currentRotation)
        
        // Create target transform with center position and horizontal rotation only
        var targetTransform = Transform()
        targetTransform.translation = centerRoomPosition.translation
        targetTransform.rotation = yawOnlyRotation  // Keep horizontal facing, remove tilt
        targetTransform.scale = SIMD3<Float>(1, 1, 1)
        
        // Use existing simple animation
        animateTransform(
            from: anchor.transform,
            to: targetTransform,
            duration: 0.8,
            completion: {
                self.cameraState.reset()
                self.isZoomedToBookshelf = false
                self.cameraState.isZoomed = false
                self.interactableObjectNearby = nil
            }
        )
    }
    
    private func extractYawRotation(from rotation: simd_quatf) -> simd_quatf {
        // Convert quaternion to rotation matrix
        let matrix = float3x3(rotation)
        
        // Extract yaw (rotation around Y axis) from the rotation matrix
        // Using atan2 of the relevant matrix components
        let yaw = atan2(matrix[0][2], matrix[2][2])
        
        // Create quaternion with only yaw rotation (no pitch or roll)
        return simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))
    }
    
    private func setupObjectsForFallingAnimation(in sceneEntity: Entity) {
        // Store original positions for each object
        var originalPositions: [Entity: SIMD3<Float>] = [:]
        
        // List of object names to animate
        let objectNames = ["bigshelf", "desk", "chest_open", "plant_shelf", "tallish_plant", 
                          "big_plant", "stereostack", "bike", "water_cooler", "trashcan",
                          "bulletin_board", "whiteboard", "stair", "drafting", "clipboard",
                          "paper_stack", "paper_stacks", "polaroids", "watercan"]
        
        // Find and setup each object
        for objectName in objectNames {
            if let object = findEntity(named: objectName, in: sceneEntity) {
                // Store original position
                originalPositions[object] = object.position
                
                // Calculate fall height (max 10 units above original position, but not higher than skydome)
                let fallHeight = Float.random(in: 8.0...12.0)
                object.position.y += fallHeight
            }
        }
        
        // Store positions for animation
        self.objectOriginalPositions = originalPositions
    }
    
    private func performIntroAnimation(anchor: AnchorEntity, sceneEntity: Entity) {
        // Target position and rotation (facing desk area)
        var targetTransform = Transform()
        targetTransform.translation = centerRoomPosition.translation // Final position at center
        
        // Face toward desk area (desk is at positive X, so rotate to face that direction)
        let deskDirection = Float.pi / 4 // 45 degrees to face desk area
        targetTransform.rotation = simd_quatf(angle: deskDirection, axis: SIMD3<Float>(0, 1, 0))
        
        // Animate with custom intro animation (camera + objects)
        animateIntroSequence(
            anchor: anchor,
            targetTransform: targetTransform,
            sceneEntity: sceneEntity,
            duration: 5.0  // Extended to 5 seconds for slower, more cinematic effect
        )
    }
    
    private func animateIntroSequence(
        anchor: AnchorEntity,
        targetTransform: Transform,
        sceneEntity: Entity,
        duration: TimeInterval
    ) {
        let startTime = CACurrentMediaTime()
        let startTransform = anchor.transform
        
        // Create animation timer
        Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { timer in
            let elapsed = CACurrentMediaTime() - startTime
            let progress = Float(min(elapsed / duration, 1.0))
            
            // Custom easing for smooth intro
            let easedProgress = self.easeOutQuart(progress)
            
            // Animate camera position (dropping down)
            let currentY = simd_mix(
                startTransform.translation.y,
                targetTransform.translation.y,
                easedProgress
            )
            
            // Create spinning motion (360 degrees + final rotation)
            // Face toward desk area (45 degrees)
            let deskDirection = Float.pi / 4
            
            // Spin 360 degrees plus the final orientation
            // Use easeOutCubic for the spin to slow down as it approaches final position
            let spinProgress = self.easeOutCubic(progress)
            let currentRotation = (Float.pi * 2 + deskDirection) * spinProgress
            
            // Apply camera transform
            var currentTransform = Transform()
            currentTransform.translation = SIMD3<Float>(
                targetTransform.translation.x,
                currentY,
                targetTransform.translation.z
            )
            currentTransform.rotation = simd_quatf(
                angle: currentRotation,
                axis: SIMD3<Float>(0, 1, 0)
            )
            currentTransform.scale = SIMD3<Float>(1, 1, 1)
            
            anchor.transform = currentTransform
            
            // Animate falling objects with staggered timing
            for (object, originalPosition) in self.objectOriginalPositions {
                // Stagger the fall based on object's original X position for visual interest
                let staggerDelay = Float(abs(originalPosition.x) * 0.02) // Reduced delay for slower fall
                
                // Make objects fall slower by adjusting the progress curve
                // They start falling immediately but take longer to complete
                let fallDuration = 2.0 // Objects take 2x longer to fall than camera takes to descend
                let objectProgress = max(0, min(1, (progress * Float(duration / fallDuration)) - staggerDelay))
                
                // Use bounce easing for objects falling
                let objectEasedProgress = self.easeOutBounce(objectProgress)
                
                // Interpolate Y position from current (elevated) to original
                let currentObjectY = simd_mix(
                    object.position.y,
                    originalPosition.y,
                    objectEasedProgress
                )
                
                // Update object position (only Y changes)
                object.position = SIMD3<Float>(
                    originalPosition.x,
                    currentObjectY,
                    originalPosition.z
                )
            }
            
            // Update position display
            self.updateCurrentPositionDisplay()
            
            if progress >= 1.0 {
                timer.invalidate()
                // Ensure final positions are exact
                anchor.transform = targetTransform
                
                // Reset all objects to exact original positions
                for (object, originalPosition) in self.objectOriginalPositions {
                    object.position = originalPosition
                }
                
                self.updateCurrentPositionDisplay()
            }
        }
    }
    
    private func easeOutBounce(_ t: Float) -> Float {
        if t < 1 / 2.75 {
            return 7.5625 * t * t
        } else if t < 2 / 2.75 {
            let t2 = t - 1.5 / 2.75
            return 7.5625 * t2 * t2 + 0.75
        } else if t < 2.5 / 2.75 {
            let t2 = t - 2.25 / 2.75
            return 7.5625 * t2 * t2 + 0.9375
        } else {
            let t2 = t - 2.625 / 2.75
            return 7.5625 * t2 * t2 + 0.984375
        }
    }
    
    private func easeOutQuart(_ t: Float) -> Float {
        return 1 - pow(1 - t, 4)
    }
    
    private func easeOutCubic(_ t: Float) -> Float {
        return 1 - pow(1 - t, 3)
    }
    
    private func easeInOutQuad(_ t: Float) -> Float {
        return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }
    
    // MARK: - Camera Movement Methods
    
    func moveCamera(forward: Float = 0, right: Float = 0, up: Float = 0) {
        guard let anchor = sceneAnchor else { return }
        
        // Don't allow movement during animation
        if cameraState.isAnimating { return }
        
        // Get current rotation to determine forward/right directions
        let rotation = anchor.transform.rotation
        
        // Calculate forward vector (negative Z in local space)
        let forwardVector = rotation.act(SIMD3<Float>(0, 0, -forward))
        
        // Calculate right vector (positive X in local space)
        let rightVector = rotation.act(SIMD3<Float>(right, 0, 0))
        
        // Apply movement
        anchor.position += forwardVector + rightVector + SIMD3<Float>(0, up, 0)
        
        updateCurrentPositionDisplay()
        checkProximityToInteractables()
    }
    
    func rotateCamera(yaw: Float = 0, pitch: Float = 0) {
        guard let anchor = sceneAnchor else { return }
        
        // Don't allow rotation during animation
        if cameraState.isAnimating { return }
        
        // Apply yaw rotation
        if yaw != 0 {
            let yawQuat = simd_quatf(angle: yaw, axis: SIMD3<Float>(0, 1, 0))
            anchor.transform.rotation = anchor.transform.rotation * yawQuat
        }
        
        updateCurrentPositionDisplay()
        checkProximityToInteractables()
    }
    
    func tiltCamera(pitch: Float) {
        guard let anchor = sceneAnchor else { return }
        
        // Don't allow tilt during animation
        if cameraState.isAnimating { return }
        
        // Apply pitch rotation
        let pitchQuat = simd_quatf(angle: pitch, axis: SIMD3<Float>(1, 0, 0))
        anchor.transform.rotation = pitchQuat * anchor.transform.rotation
        
        updateCurrentPositionDisplay()
    }
    
    func capturePositionForObject(_ object: InteractableObject) {
        guard let anchor = sceneAnchor else { return }
        
        let currentPosition = CameraPosition(from: anchor.transform)
        
        switch object {
        case .bookshelf:
            cameraState.bookshelfPosition = currentPosition
            print("Captured bookshelf position: \(currentPosition.description)")
        case .desk:
            cameraState.deskPosition = currentPosition
            print("Captured desk position: \(currentPosition.description)")
        case .chest:
            cameraState.chestPosition = currentPosition
            print("Captured chest position: \(currentPosition.description)")
        }
    }
    
    func clearCapturedCameraPositions() {
        cameraState.bookshelfPosition = nil
        cameraState.deskPosition = nil
        cameraState.chestPosition = nil
    }
    
    func animateToObject(_ object: InteractableObject) {
        guard let anchor = sceneAnchor else { return }
        
        // Get the target position for the object
        let targetPosition: CameraPosition?
        switch object {
        case .bookshelf:
            targetPosition = cameraState.bookshelfPosition
        case .desk:
            targetPosition = cameraState.deskPosition
        case .chest:
            targetPosition = cameraState.chestPosition
        }
        
        // If we have a captured position, use it (which we always will with hardcoded values)
        if let target = targetPosition {
            // Don't save original transform - we always return to center
            
            animateTransform(
                from: anchor.transform,
                to: target.transform,
                duration: 1.2,
                completion: {
                    self.cameraState.isZoomed = true
                    self.isZoomedToBookshelf = true // Keep for UI compatibility
                    self.interactableObjectNearby = nil
                }
            )
        } else {
            // Fallback: Calculate position dynamically
            if let entity = findEntity(named: object.entityName, in: anchor) {
                animateToEntity(entity)
            }
        }
    }
    
    private func animateToEntity(_ entity: Entity) {
        guard let anchor = sceneAnchor else { return }
        
        // Save original transform
        if cameraState.originalTransform == nil {
            cameraState.originalTransform = anchor.transform
        }
        
        // Calculate target position based on entity
        let entityPosition = entity.position(relativeTo: anchor)
        let entityBounds = entity.visualBounds(relativeTo: anchor)
        
        // Calculate optimal viewing distance
        let boundingRadius = max(
            entityBounds.extents.x,
            entityBounds.extents.y,
            entityBounds.extents.z
        ) * 0.5
        
        let viewingDistance: Float = boundingRadius * 2.5
        
        // Create target transform
        var targetTransform = Transform()
        targetTransform.translation = SIMD3<Float>(
            -entityPosition.x,
            -1.7 - entityPosition.y * 0.5,
            -entityPosition.z + viewingDistance
        )
        targetTransform.rotation = simd_quatf() // Reset rotation for now
        
        animateTransform(
            from: anchor.transform,
            to: targetTransform,
            duration: 1.2,
            completion: {
                self.cameraState.isZoomed = true
                self.isZoomedToBookshelf = true
                self.interactableObjectNearby = nil
            }
        )
    }
    
    private func animateTransform(from: Transform, to: Transform, duration: TimeInterval, completion: (() -> Void)? = nil) {
        guard let anchor = sceneAnchor else { return }
        
        // Prevent multiple animations
        if cameraState.isAnimating { return }
        
        cameraState.isAnimating = true
        cameraState.animationProgress = 0
        
        let startTime = CACurrentMediaTime()
        
        // Invalidate any existing timer
        cameraState.animationTimer?.invalidate()
        
        // Create animation timer
        cameraState.animationTimer = Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { timer in
            let elapsed = CACurrentMediaTime() - startTime
            let progress = Float(min(elapsed / duration, 1.0))
            
            // Use easing function
            let easedProgress = EasingFunction.easeInOutCubic(progress)
            
            // Interpolate transform
            let currentTransform = Transform.interpolate(
                from: from,
                to: to,
                progress: easedProgress
            )
            
            anchor.transform = currentTransform
            self.cameraState.animationProgress = progress
            
            // Update position display during animation
            self.updateCurrentPositionDisplay()
            
            if progress >= 1.0 {
                timer.invalidate()
                self.cameraState.animationTimer = nil
                self.cameraState.isAnimating = false
                self.cameraState.animationProgress = 1.0
                
                // Call completion handler
                completion?()
            }
        }
    }
    
    private func updateCurrentPositionDisplay() {
        guard let anchor = sceneAnchor else {
            currentAnchorPosition = "No anchor"
            return
        }
        
        let pos = anchor.position
        let rot = anchor.transform.rotation
        
        currentAnchorPosition = String(
            format: "Pos: (%.2f, %.2f, %.2f) Rot: (%.2f, %.2f, %.2f, %.2f)",
            pos.x, pos.y, pos.z,
            rot.vector.x, rot.vector.y, rot.vector.z, rot.vector.w
        )
    }
}