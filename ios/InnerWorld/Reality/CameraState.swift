//
//  CameraState.swift
//  InnerWorld
//
//  Camera animation state management
//

import Foundation
import RealityKit
import simd

struct CameraState {
    var isAnimating: Bool = false
    var isZoomed: Bool = false
    var originalTransform: Transform?
    var targetEntity: Entity?
    var animationProgress: Float = 0
    var animationTimer: Timer?
    
    // Stored positions for interactive objects
    var bookshelfPosition: CameraPosition?
    var deskPosition: CameraPosition?
    var chestPosition: CameraPosition?
    
    mutating func reset() {
        isAnimating = false
        isZoomed = false
        originalTransform = nil
        targetEntity = nil
        animationProgress = 0
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

struct CameraPosition: Codable {
    let translation: SIMD3<Float>
    let rotation: simd_quatf
    let scale: SIMD3<Float>
    
    init(translation: SIMD3<Float>, rotation: simd_quatf, scale: SIMD3<Float> = SIMD3<Float>(1, 1, 1)) {
        self.translation = translation
        self.rotation = rotation
        self.scale = scale
    }
    
    init(from transform: Transform) {
        self.translation = transform.translation
        self.rotation = transform.rotation
        self.scale = transform.scale
    }
    
    var transform: Transform {
        var t = Transform()
        t.translation = translation
        t.rotation = rotation
        t.scale = scale
        return t
    }
    
    // Custom encoding/decoding for simd_quatf
    enum CodingKeys: String, CodingKey {
        case translation
        case rotationVector
        case scale
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(translation, forKey: .translation)
        try container.encode(scale, forKey: .scale)
        
        // Encode quaternion as vector
        let rotVector = SIMD4<Float>(rotation.vector)
        try container.encode(rotVector, forKey: .rotationVector)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        translation = try container.decode(SIMD3<Float>.self, forKey: .translation)
        scale = try container.decode(SIMD3<Float>.self, forKey: .scale)
        
        // Decode quaternion from vector
        let rotVector = try container.decode(SIMD4<Float>.self, forKey: .rotationVector)
        rotation = simd_quatf(vector: rotVector)
    }
    
    var description: String {
        return String(format: "Pos: (%.2f, %.2f, %.2f)", translation.x, translation.y, translation.z)
    }
}

// Easing functions for smooth animations
enum EasingFunction {
    static func easeInOutCubic(_ t: Float) -> Float {
        return t < 0.5
            ? 4 * t * t * t
            : 1 - pow(-2 * t + 2, 3) / 2
    }
    
    static func easeInOutQuad(_ t: Float) -> Float {
        return t < 0.5
            ? 2 * t * t
            : 1 - pow(-2 * t + 2, 2) / 2
    }
    
    static func easeOutQuart(_ t: Float) -> Float {
        return 1 - pow(1 - t, 4)
    }
    
    static func linear(_ t: Float) -> Float {
        return t
    }
}

// Transform interpolation utilities
extension Transform {
    static func interpolate(from: Transform, to: Transform, progress: Float) -> Transform {
        var result = Transform()
        
        // Interpolate translation
        result.translation = simd_mix(from.translation, to.translation, SIMD3<Float>(repeating: progress))
        
        // Interpolate rotation using spherical linear interpolation
        result.rotation = simd_slerp(from.rotation, to.rotation, progress)
        
        // Interpolate scale
        result.scale = simd_mix(from.scale, to.scale, SIMD3<Float>(repeating: progress))
        
        return result
    }
}