//
//  SphereNode.swift
//  HexaSphereGrid
//
//  Created by Nicolas Laurent on 24/04/2025.
//

import SwiftUI

public struct GridCoord: Hashable, Codable {
    public let q: Int
    public let r: Int
    
    public init(q: Int, r: Int) {
        self.q = q
        self.r = r
    }
}
 
public struct SphereNode: HexagonDataProtocol {
    
    
    public init(id : String, coord: GridCoord, name: String, weight: CGFloat, unlocked: Bool = false, progress: Double? = nil) {
        self.id = id
        self.q = coord.q
        self.r = coord.r
        self.name = name
        self.weight = weight
        self.unlocked = unlocked
        self.progress = progress
    }
    
    public var id : String
    
    public let name: String
    public var weight: CGFloat
    
    public var progress: Double?
    
    /// État d'activation (false = locked, true = activated)
    public var unlocked: Bool = false
    public var q: Int
    public var r: Int
    
    public static func == (lhs: SphereNode, rhs: SphereNode) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func coordinate() -> GridCoord {
        return GridCoord(q: q, r: r)
    }
    
    
}

public protocol HexagonDataProtocol: Identifiable, Codable, Hashable {
    
    var id: String { get }
    var name: String { get }
    
    var q: Int { get }
    var r: Int { get }
    
    var progress : Double? { get }
}
    

