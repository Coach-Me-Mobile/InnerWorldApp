//
//  CameraMovementWidget.swift
//  InnerWorld
//
//  Movement controls and position capture widget
//

import SwiftUI
import simd

struct CameraMovementWidget: View {
    @ObservedObject var arViewContainer: ARViewContainer
    @State private var captureBookshelf = false
    @State private var captureDesk = false
    @State private var captureChest = false
    @State private var showExportSheet = false
    
    // Movement increments
    private let moveIncrement: Float = 0.1
    private let rotateIncrement: Float = 0.05
    private let tiltIncrement: Float = 0.02
    
    var body: some View {
        VStack(spacing: 15) {
            // Title
            Text("Camera Movement Controls")
                .font(.headline)
                .foregroundColor(.white)
            
            // Current Position Display
            VStack(alignment: .leading, spacing: 5) {
                Text("Current Anchor Position")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(arViewContainer.currentAnchorPosition)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.3)))
            }
            
            // Movement Controls
            VStack(spacing: 10) {
                // Forward/Backward and Turn controls
                HStack(spacing: 20) {
                    // Turn Left
                    Button(action: { arViewContainer.rotateCamera(yaw: -rotateIncrement) }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(MovementButtonStyle())
                    
                    // Forward/Backward
                    VStack(spacing: 5) {
                        Button(action: { arViewContainer.moveCamera(forward: moveIncrement) }) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16))
                        }
                        .buttonStyle(MovementButtonStyle())
                        
                        Button(action: { arViewContainer.moveCamera(forward: -moveIncrement) }) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 16))
                        }
                        .buttonStyle(MovementButtonStyle())
                    }
                    
                    // Turn Right
                    Button(action: { arViewContainer.rotateCamera(yaw: rotateIncrement) }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(MovementButtonStyle())
                }
                
                // Left/Right strafe controls
                HStack(spacing: 20) {
                    Button(action: { arViewContainer.moveCamera(right: -moveIncrement) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                            Text("Left")
                        }
                        .font(.system(size: 12))
                    }
                    .buttonStyle(MovementButtonStyle(width: 60))
                    
                    Button(action: { arViewContainer.moveCamera(right: moveIncrement) }) {
                        HStack(spacing: 4) {
                            Text("Right")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 12))
                    }
                    .buttonStyle(MovementButtonStyle(width: 60))
                }
                
                // Up/Down controls
                HStack(spacing: 20) {
                    Button(action: { arViewContainer.moveCamera(up: moveIncrement) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle")
                            Text("Higher")
                        }
                        .font(.system(size: 12))
                    }
                    .buttonStyle(MovementButtonStyle(width: 70))
                    
                    Button(action: { arViewContainer.moveCamera(up: -moveIncrement) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle")
                            Text("Lower")
                        }
                        .font(.system(size: 12))
                    }
                    .buttonStyle(MovementButtonStyle(width: 70))
                }
                
                // Tilt controls
                HStack(spacing: 20) {
                    Button(action: { arViewContainer.tiltCamera(pitch: -tiltIncrement) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.up")
                            Text("Tilt Up")
                        }
                        .font(.system(size: 12))
                    }
                    .buttonStyle(MovementButtonStyle(width: 70))
                    
                    Button(action: { arViewContainer.tiltCamera(pitch: tiltIncrement) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.down")
                            Text("Tilt Down")
                        }
                        .font(.system(size: 12))
                    }
                    .buttonStyle(MovementButtonStyle(width: 70))
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Position Capture Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Capture Positions")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                // Bookshelf capture
                HStack {
                    Toggle(isOn: $captureBookshelf) {
                        HStack {
                            Image(systemName: captureBookshelf ? "checkmark.square.fill" : "square")
                                .foregroundColor(captureBookshelf ? .green : .white.opacity(0.6))
                            Text("Bigshelf Position")
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                        }
                    }
                    .toggleStyle(.automatic)
                    .onChange(of: captureBookshelf) { newValue in
                        if newValue {
                            arViewContainer.capturePositionForObject(.bookshelf)
                        }
                    }
                    
                    if arViewContainer.cameraState.bookshelfPosition != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                    }
                }
                
                // Desk capture
                HStack {
                    Toggle(isOn: $captureDesk) {
                        HStack {
                            Image(systemName: captureDesk ? "checkmark.square.fill" : "square")
                                .foregroundColor(captureDesk ? .green : .white.opacity(0.6))
                            Text("Desk Position")
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                        }
                    }
                    .toggleStyle(.automatic)
                    .onChange(of: captureDesk) { newValue in
                        if newValue {
                            arViewContainer.capturePositionForObject(.desk)
                        }
                    }
                    
                    if arViewContainer.cameraState.deskPosition != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                    }
                }
                
                // Chest capture
                HStack {
                    Toggle(isOn: $captureChest) {
                        HStack {
                            Image(systemName: captureChest ? "checkmark.square.fill" : "square")
                                .foregroundColor(captureChest ? .green : .white.opacity(0.6))
                            Text("Chest Position")
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                        }
                    }
                    .toggleStyle(.automatic)
                    .onChange(of: captureChest) { newValue in
                        if newValue {
                            arViewContainer.capturePositionForObject(.chest)
                        }
                    }
                    
                    if arViewContainer.cameraState.chestPosition != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: 10) {
                Button(action: {
                    arViewContainer.clearCapturedCameraPositions()
                    captureBookshelf = false
                    captureDesk = false
                    captureChest = false
                }) {
                    Text("Clear All")
                        .font(.system(size: 13))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.red.opacity(0.7)))
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    showExportSheet = true
                }) {
                    Text("Export Positions")
                        .font(.system(size: 13))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.green.opacity(0.7)))
                        .foregroundColor(.white)
                }
            }
            
            // Test Animation Buttons
            if arViewContainer.hasAnyCapturedPositions {
                Divider()
                    .background(Color.white.opacity(0.3))
                
                VStack(spacing: 8) {
                    Text("Test Animations")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 8) {
                        if arViewContainer.cameraState.bookshelfPosition != nil {
                            Button(action: {
                                arViewContainer.animateToObject(.bookshelf)
                            }) {
                                Text("→ Shelf")
                                    .font(.system(size: 11))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.blue.opacity(0.7)))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        if arViewContainer.cameraState.deskPosition != nil {
                            Button(action: {
                                arViewContainer.animateToObject(.desk)
                            }) {
                                Text("→ Desk")
                                    .font(.system(size: 11))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.blue.opacity(0.7)))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        if arViewContainer.cameraState.chestPosition != nil {
                            Button(action: {
                                arViewContainer.animateToObject(.chest)
                            }) {
                                Text("→ Chest")
                                    .font(.system(size: 11))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.blue.opacity(0.7)))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .sheet(isPresented: $showExportSheet) {
            CameraPositionExportView(arViewContainer: arViewContainer)
        }
    }
}

struct MovementButtonStyle: ButtonStyle {
    let width: CGFloat
    let height: CGFloat
    
    init(width: CGFloat = 40, height: CGFloat = 40) {
        self.width = width
        self.height = height
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(width: width, height: height)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ? Color.blue.opacity(0.8) : Color.white.opacity(0.2))
            )
            .foregroundColor(Color.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CameraPositionExportView: View {
    @ObservedObject var arViewContainer: ARViewContainer
    @Environment(\.dismiss) var dismiss
    
    var exportText: String {
        var text = "Camera Positions Export\n"
        text += "========================\n\n"
        
        if let pos = arViewContainer.cameraState.bookshelfPosition {
            text += "Bookshelf Position:\n"
            text += "  Translation: \(formatVector(pos.translation))\n"
            text += "  Rotation: \(formatQuaternion(pos.rotation))\n\n"
        }
        
        if let pos = arViewContainer.cameraState.deskPosition {
            text += "Desk Position:\n"
            text += "  Translation: \(formatVector(pos.translation))\n"
            text += "  Rotation: \(formatQuaternion(pos.rotation))\n\n"
        }
        
        if let pos = arViewContainer.cameraState.chestPosition {
            text += "Chest Position:\n"
            text += "  Translation: \(formatVector(pos.translation))\n"
            text += "  Rotation: \(formatQuaternion(pos.rotation))\n\n"
        }
        
        return text
    }
    
    private func formatVector(_ v: SIMD3<Float>) -> String {
        return String(format: "(%.3f, %.3f, %.3f)", v.x, v.y, v.z)
    }
    
    private func formatQuaternion(_ q: simd_quatf) -> String {
        return String(format: "(%.3f, %.3f, %.3f, %.3f)", q.vector.x, q.vector.y, q.vector.z, q.vector.w)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    Text(exportText)
                        .font(.system(size: 12, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                Button("Copy to Clipboard") {
                    UIPasteboard.general.string = exportText
                    dismiss()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .navigationTitle("Export Camera Positions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}