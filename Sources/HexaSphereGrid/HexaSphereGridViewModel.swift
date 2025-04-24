//
//  HexaSphereGridViewModel.swift
//  HexaSphereGrid
//
//  Created by Nicolas Laurent on 24/04/2025.
//

import Foundation


public final class HexaSphereGridViewModel: ObservableObject {
    
    @Published public var currentSelectedSphereNode: SphereNode?
    @Published public var sphereNodes: [SphereNode] = []
 
    public init() {
        
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
