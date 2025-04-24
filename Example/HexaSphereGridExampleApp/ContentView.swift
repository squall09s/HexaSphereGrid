//
//  ContentView.swift
//  HexaSphereGridExampleApp
//
//  Created by Nicolas Laurent on 22/04/2025.
//

import SwiftUI
import SwiftData
import HexaSphereGrid

struct ContentView: View {
    
    @StateObject private var viewModel = HexaSphereGridViewModel()
    
    var body: some View {
        
        HexaSphereGridView(viewModel: viewModel) { sphereNode in
            VStack {
                
                Text(sphereNode.name)
                    .padding()
                
                switch viewModel.sphereNodeState(forID: sphereNode.id) {
                case .unlocked:
                    
                    if viewModel.currentSelectedSphereNode?.id != sphereNode.id {
                        Button("Select") {
                            viewModel.currentSelectedSphereNode = sphereNode
                        }
                    }
                    
                case .unlockable:
                    Button("Unlock") {
                        viewModel.unlockSphereNode(withID: sphereNode.id)
                    }
                case .locked:
                    EmptyView()
                }
            }
        }.ignoresSafeArea()
        .onAppear {
            viewModel.sphereNodes = loadSpheres()
        }
    }
}



// HexMapView<EmptyView>()

#Preview {
    ContentView()
}
