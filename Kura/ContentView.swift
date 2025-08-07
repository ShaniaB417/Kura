//
//  ContentView.swift
//  Kura
//
//  Created by Shania Brown on 6/24/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

enum DecorationType: String, CaseIterable {
    case rock = "Zen_Rocks"
    case rake = "Zen_Rake"
    case lantern = "Zen_Lantern"
}

struct ContentView: View {
    @State private var heldEntity: Entity?
    @State private var realityContent: RealityViewContent?

    var body: some View {
        ZStack {
            RealityView { content in
                self.realityContent = content
                await setupScene(content: content)
            }
            .gesture(
                TapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        let entity = value.entity
                        heldEntity?.removeFromParent()

                        let headAnchor = AnchorEntity(.head)
                        entity.setPosition(SIMD3<Float>(0, 0, -0.3), relativeTo: nil)
                        headAnchor.addChild(entity)
                        realityContent?.add(headAnchor)

                        heldEntity = entity
                    }
            )

            VStack {
                Spacer()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(DecorationType.allCases, id: \.self) { type in
                            Button(action: {
                                Task {
                                    await placeDecoration(type)
                                }
                            }) {
                                Text(type.rawValue.replacingOccurrences(of: "Zen_", with: ""))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color(.systemGray5))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(20)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }

    func setupScene(content: RealityViewContent) async {
        do {
            let (floor, rock, rake, lantern) = try await loadAllEntities()

            floor.scale = SIMD3<Float>(0.09, 0.09, 0.09)
            floor.position = .zero
            content.add(floor)

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
            print(" Failed to load models: \(error)")
        }
    }

    func placeDecoration(_ type: DecorationType) async {
        do {
            let entity = try await Entity(named: type.rawValue, in: .main)
            entity.scale = SIMD3<Float>(0.01, 0.01, 0.01)
            entity.position = SIMD3<Float>(0, 0, -0.2)
            entity.name = type.rawValue
            entity.generateCollisionShapes(recursive: true)
            entity.components.set(InputTargetComponent(allowedInputTypes: .all))

            let anchor = AnchorEntity(.head)
            anchor.addChild(entity)
            realityContent?.add(anchor)

            heldEntity = entity
        } catch {
            print("Failed to load \(type.rawValue): \(error)")
        }
    }

    func loadAllEntities() async throws -> (Entity, Entity, Entity, Entity) {
        if let bundleURL = Bundle.main.url(forResource: "RealityKitContent", withExtension: "bundle"),
           let contentBundle = Bundle(url: bundleURL) {
            return (
                try await Entity(named: "zengarden", in: contentBundle),
                try await Entity(named: "Zen_Rocks", in: contentBundle),
                try await Entity(named: "Zen_Rake", in: contentBundle),
                try await Entity(named: "Zen_Lantern", in: contentBundle)
            )
        } else {
            return (
                try await Entity(named: "zengarden", in: .main),
                try await Entity(named: "Zen_Rocks", in: .main),
                try await Entity(named: "Zen_Rake", in: .main),
                try await Entity(named: "Japanese_Lantern_Tōrō", in: .main)
            )
        }
    }
}


