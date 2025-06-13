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
    
    @Published public var currentCenter: GridCoord = GridCoord(q: 0, r: 0 )
    
    @Published public var currentSelectedSphereNode: SphereNode?
    @Published var highlightedSphereNode: SphereNode? = nil
    
    @Published public var sphereNodes: [SphereNode] = []
    @Published var nodeOverlays: [UUID: AnyView] = [:]
    
  
    public var dataSource: SphereNodeDataSource?
    
    private var imageCache: [String: Image] = [:]
    
    public init(dataSource: SphereNodeDataSource? = nil) {
        self.dataSource = dataSource
    }
    
    public func configure(with nodes : [any HexagonDataProtocol]){
        self.sphereNodes = nodes.map({ _nodeData in
            return SphereNode(id: _nodeData.id,
                              coord: GridCoord(q: _nodeData.q, r: _nodeData.r),
                              name: _nodeData.name,
                              weight: 1,
                              progress: _nodeData.progress)
        
        })
    }
    
    // Exemple d'utilisation dans ta vue ou logique
    public func color(for node: SphereNode) -> Color {
        dataSource?.color(for: node) ?? Color.black
    }
    
    public func image(for node: SphereNode) -> Image? {
        
        if self.sphereNodeState(forID: node.id) == .locked {
            
            return Image(systemName: "seal.fill")
            
        }else{
            
            if let cached = imageCache[node.id.uuidString] {
                return cached
            } else if let generated = dataSource?.image(for: node) {
                imageCache[node.id.uuidString] = generated
                return generated
            } else {
                return nil
            }
        }
    }
    
    public func sphereNodeState(forID id : UUID) -> HexagonState {
        
        guard let idx = sphereNodes.firstIndex(where: { $0.id == id }) else { return .locked }
        
        if sphereNodes[idx].unlocked {
            
            return .unlocked
            
        } else {
            
            /// Identifiants des cases déverrouillables (voisines des cases déjà unlockées)
            var unlockableSphereNodeIDs: Set<UUID> {
                var set = Set<UUID>()
                for sphereNode in sphereNodes where sphereNode.unlocked {
                    set.formUnion(neighborIDs(for: sphereNode))
                }
                // Ne pas proposer celles déjà déverrouillées
                set.subtract(sphereNodes.filter { $0.unlocked }.map { $0.id })
                return set
            }
            
            if sphereNodes[idx].unlocked {
                return .unlocked
            } else {
                return unlockableSphereNodeIDs.contains(id) ? .unlockable : .locked
            }
        }
    }
    
    /// Tente de déverrouiller une case si elle est voisine d’une case unlockée
    public func updateState(forNodeId id: UUID, unlocked : Bool) {
        guard let idx = sphereNodes.firstIndex(where: { $0.id == id }) else { return }
        sphereNodes[idx].unlocked = true
    }
    
    public func neighborIDs(for node: SphereNode) -> [UUID] {
        let directions = [
            GridCoord(q: 1, r: 0), GridCoord(q: 1, r: -1), GridCoord(q: 0, r: -1),
            GridCoord(q: -1, r: 0), GridCoord(q: -1, r: 1), GridCoord(q: 0, r: 1)
        ]
        
        return directions.compactMap { offset in
            let neighborCoord = GridCoord(q: node.q + offset.q, r: node.r + offset.r)
            return sphereNodes.first(where: { $0.coordinate() == neighborCoord })?.id
        }
    }
    
    public func deselectHighlightedNode() {
        highlightedSphereNode = nil
    }
    
    public func display(overlays: [(id: UUID, view: AnyView)]) {
        var newDict: [UUID: AnyView] = [:]
        for overlay in overlays {
            newDict[overlay.id] = overlay.view
        }
        self.nodeOverlays = newDict
    }
    
    
}
