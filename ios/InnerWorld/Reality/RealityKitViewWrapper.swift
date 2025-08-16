//
//  RealityKitViewWrapper.swift
//  InnerWorld
//
//  UIViewRepresentable wrapper for ARView
//

import SwiftUI
import RealityKit

struct RealityKitViewWrapper: UIViewRepresentable {
    let arViewContainer: ARViewContainer
    
    func makeUIView(context: Context) -> ARView {
        return arViewContainer.setupView()
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Updates handled through the container
    }
}