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
    @State private var showDebugPanel = false
    @State private var showExportedPositions = false
    
    var body: some View {
        ZStack {
            RealityKitViewWrapper(arViewContainer: arViewContainer)
                .edgesIgnoringSafeArea(.all)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only allow panning when not zoomed to bookshelf
                            if !arViewContainer.isZoomedToBookshelf {
                                let delta = CGSize(
                                    width: value.translation.width - lastDragLocation.width,
                                    height: value.translation.height - lastDragLocation.height
                                )
                                updateCameraRotation(delta: delta)
                                lastDragLocation = value.translation
                            }
                        }
                        .onEnded { _ in
                            lastDragLocation = .zero
                        }
                )
            
            // Interaction hint overlay
            if let interactable = arViewContainer.interactableObjectNearby {
                VStack {
                    Spacer()
                    
                    HStack {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 20))
                        Text(getInteractionText(for: interactable))
                            .font(.system(size: 16, weight: .medium))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.bottom, 120)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .animation(.easeInOut(duration: 0.3), value: arViewContainer.interactableObjectNearby)
            }
            
            // Interaction feedback
            if let tapped = arViewContainer.lastTappedObject {
                VStack {
                    Text(getInteractionFeedback(for: tapped))
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.9))
                        )
                        .foregroundColor(.white)
                        .padding(.top, 100)
                    
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .onAppear {
                    // Clear the message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            arViewContainer.lastTappedObject = nil
                        }
                    }
                }
            }
            
            // Back button when zoomed to bookshelf
            if arViewContainer.isZoomedToBookshelf {
                VStack {
                    Spacer()
                    
                    Button(action: {
                        arViewContainer.returnToOriginalView()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 24))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.6))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.bottom, 120)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .animation(.easeInOut(duration: 0.3), value: arViewContainer.isZoomedToBookshelf)
            }
            
            // Debug button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        showDebugPanel.toggle()
                        arViewContainer.debugMode = showDebugPanel
                    }) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.orange.opacity(0.8)))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 60)
                }
                Spacer()
            }
            
            // Debug Panel
            if showDebugPanel {
                VStack(spacing: 15) {
                    Text("Object Position Capture")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    // Current desk position
                    Text(arViewContainer.currentDeskPosition)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.5)))
                    
                    // Recording toggle
                    Toggle(isOn: $arViewContainer.isRecording) {
                        HStack {
                            Image(systemName: arViewContainer.isRecording ? "record.circle.fill" : "record.circle")
                                .foregroundColor(arViewContainer.isRecording ? .red : .white)
                            Text(arViewContainer.isRecording ? "Recording Positions" : "Start Recording")
                                .foregroundColor(.white)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .red))
                    
                    // Captured positions count
                    Text("Captured: \(arViewContainer.capturedPositions.count) positions")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 10) {
                        // Clear button
                        Button(action: {
                            arViewContainer.clearCapturedPositions()
                        }) {
                            Text("Clear")
                                .font(.system(size: 14))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.8)))
                                .foregroundColor(.white)
                        }
                        
                        // Export button
                        Button(action: {
                            showExportedPositions = true
                        }) {
                            Text("Export")
                                .font(.system(size: 14))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.green.opacity(0.8)))
                                .foregroundColor(.white)
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
                .padding(.top, 100)
                .padding(.horizontal, 20)
                Spacer()
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
        .sheet(isPresented: $showExportedPositions) {
            VStack {
                Text("Captured Positions")
                    .font(.headline)
                    .padding()
                
                ScrollView {
                    Text(arViewContainer.exportPositions())
                        .font(.system(size: 11, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                Button("Copy to Clipboard") {
                    UIPasteboard.general.string = arViewContainer.exportPositions()
                    showExportedPositions = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Done") {
                    showExportedPositions = false
                }
                .padding()
            }
        }
    }
    
    private func getInteractionText(for object: String) -> String {
        switch object {
        case "bigshelf":
            return "Tap bookshelf to interact"
        case "chest_open":
            return "Tap box to play Mini Games"
        case "desk":
            return "Tap to interact with Desk"
        default:
            return "Tap to interact"
        }
    }
    
    private func getInteractionFeedback(for object: String) -> String {
        if object.contains("shelf") {
            return "Opening bookshelf..."
        } else if object.contains("chest") {
            return "Loading Mini Games..."
        } else if object.contains("desk") {
            return "Opening desk workspace..."
        } else {
            return "Interacting..."
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
