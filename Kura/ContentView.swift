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
    @State private var heldEntity: Entity?
    @State private var realityContent: RealityViewContent? // Store content reference

    var body: some View {
        RealityView { content in
            self.realityContent = content //  Save RealityKit scene reference
            await setupScene(content: content)
        }
        .gesture(
            TapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    let entity = value.entity
                    print("👁️ Tapped: \(entity.name)")

                    // Remove previously held object
                    heldEntity?.removeFromParent()

                    // Create head anchor and reparent entity
                    let headAnchor = AnchorEntity(.head)
                    entity.setPosition(SIMD3<Float>(0, 0, -0.3), relativeTo: nil) // Place slightly in front of face
                    headAnchor.addChild(entity)

                    //  Add anchor to saved content scene
                    realityContent?.add(headAnchor)

                    // Track the new held entity
                    heldEntity = entity
                }
        )
    }

    func setupScene(content: RealityViewContent) async {
        // Add floor
        let floor = ModelEntity(
            mesh: .generatePlane(width: 1.5, depth: 1.5),
            materials: [SimpleMaterial(color: .brown, isMetallic: false)]
        )
        floor.position = SIMD3<Float>(0, 0, 0)
        content.add(floor)

        do {
            let (rock, rake, lantern) = try await loadEntities()

            let objects = [
                (rock, SIMD3<Float>(-0.3, 0.05, 0)),
                (rake, SIMD3<Float>( 0.3, 0.05, 0)),
                (lantern, SIMD3<Float>(0.0, 0.05, 0))
            ]

            for (entity, position) in objects {
                entity.scale = SIMD3<Float>(0.001, 0.001, 0.001)
                entity.position = position
                entity.name = entity.name.isEmpty ? "object" : entity.name
                entity.generateCollisionShapes(recursive: true)
                entity.components.set(InputTargetComponent(allowedInputTypes: .all))
                content.add(entity)
            }

        } catch {
            print("❌ Failed to load models: \(error)")
        }
    }

    func loadEntities() async throws -> (Entity, Entity, Entity) {
        if let bundleURL = Bundle.main.url(forResource: "RealityKitContent", withExtension: "bundle"),
           let contentBundle = Bundle(url: bundleURL) {
            return (
                try await Entity(named: "Zen_Rocks", in: contentBundle),
                try await Entity(named: "Zen_Rake", in: contentBundle),
                try await Entity(named: "Zen_Lantern", in: contentBundle)
            )
        } else {
            return (
                try await Entity(named: "Zen_Rocks", in: .main),
                try await Entity(named: "Zen_Rake", in: .main),
                try await Entity(named: "Japanese_Lantern_Tōrō", in: .main)
            )
        }
    }
}
