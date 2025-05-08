//
//  HexaSphereGridViewModel.swift
//  HexaSphereGrid
//
//  Created by Nicolas Laurent on 24/04/2025.
//

import SwiftUI
import Foundation


public protocol SphereNodeDataSource {
    func image(for node: SphereNode) -> Image?
    func color(for node: SphereNode) -> Color
}


public final class HexaSphereGridViewModel: ObservableObject {
    
    @Published public var currentSelectedSphereNode: SphereNode?
    @Published var sphereNodes: [SphereNode] = []
    
    public var dataSource: SphereNodeDataSource?
    
    private var imageCache: [UUID: Image] = [:]
    
    public init(dataSource: SphereNodeDataSource? = nil) {
        self.dataSource = dataSource
    }
    
    public func configure(with rootNode : SphereNodeData){
        self.sphereNodes = buildNodes(rootNode: rootNode)
    }
    
    // Exemple d'utilisation dans ta vue ou logique
    public func color(for node: SphereNode) -> Color {
        dataSource?.color(for: node) ?? node.color
    }
    
    public func image(for node: SphereNode) -> Image? {
        
        if self.sphereNodeState(forID: node.id) == .locked {
            
            return Image(systemName: "seal.fill")
            
        }else{
            
            if let cached = imageCache[node.id] {
                return cached
            } else if let generated = dataSource?.image(for: node) {
                imageCache[node.id] = generated
                return generated
            } else {
                return nil
            }
        }
    }
    
    public func sphereNodeState(forID id : UUID) -> HexagonState {
        
        guard let idx = sphereNodes.firstIndex(where: { $0.id == id }) else { return .locked }
        
        if sphereNodes[idx].isActivated {
            
            return .unlocked
            
        } else {
            
            /// Identifiants des cases déverrouillables (voisines des cases déjà unlockées)
            var unlockableSphereNodeIDs: Set<UUID> {
                var set = Set<UUID>()
                for sphereNode in sphereNodes where sphereNode.isActivated {
                    set.formUnion(sphereNode.linkedNodeIDs)
                }
                // Ne pas proposer celles déjà déverrouillées
                set.subtract(sphereNodes.filter { $0.isActivated }.map { $0.id })
                return set
            }
            return unlockableSphereNodeIDs.contains(id) ? .unlockable : .locked
        }
    }
    
    /// Tente de déverrouiller une case si elle est voisine d’une case unlockée
    public func unlockSphereNode(withID id: UUID) {
        if case .unlockable = sphereNodeState(forID: id) {
            guard let idx = sphereNodes.firstIndex(where: { $0.id == id }) else { return }
            sphereNodes[idx].isActivated = true
        }
    }
    
}
