//
//  ContentView.swift
//  Kura
//
//  Created by Shania Brown on 6/24/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @State private var sceneReady = false
    @State private var rockEntity: Entity?
    
    var body: some View {
        RealityView { content in
            // 1. First do all synchronous setup
            let floor = ModelEntity(
                mesh: .generatePlane(width: 1.5, depth: 1.5),
                materials: [SimpleMaterial(color: .systemGray6, isMetallic: false)]
            )
            content.add(floor)
            
            // 2. Then load async assets
            Task {
                await loadRockAsset()
                sceneReady = true
            }
        } update: { content in
            // 3. Add async-loaded entities when ready
            if sceneReady, let rock = rockEntity, !content.entities.contains(rock) {
                content.add(rock)
            }
        }
    }
    
    @MainActor
    private func loadRockAsset() async {
        do {
            let rock = try await Entity(named: "Zen_Rocks.usdz")
            rock.scale = [0.01, 0.01, 0.01]
            rock.position = [0, 0.05, 0]
            rockEntity = rock
        } catch {
            print("Failed to load rock:", error)
            // Create fallback entity
            let fallback = ModelEntity(
                mesh: .generateSphere(radius: 0.05),
                materials: [SimpleMaterial(color: .gray, isMetallic: false)]
            )
            fallback.position = [0, 0.05, 0]
            rockEntity = fallback
        }
    }
}
