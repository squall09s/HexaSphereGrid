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
    
    @StateObject private var viewModel = HexaSphereGridViewModel(dataSource: MyNodeStyleProvider())
    
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
                            
                            //let Value = sphereNode.metadataValue(forKey: "metadata_int", as: Int.self)
                            //let Value = sphereNode.metadataValue(forKey: "metadata_string", as: String.self)
                        }
                    }
                    
                case .unlockable:
                    Button("Unlock") {
                        viewModel.unlockSphereNode(withID: sphereNode.id)
                    }
                case .locked:
                    Text("Locked")
                }
            }
        }.ignoresSafeArea()
        .onAppear {
            
            let url = Bundle.main.url(forResource: "FakeNodeData", withExtension: "json")!
            let data = try? Data(contentsOf: url)
            
            if let data = data {
                
                do {
                    let root = try JSONDecoder().decode(SphereNodeData.self, from: data)
                    viewModel.configure(with: root)
                } catch {
                    print(error)
                }
                
                
            } else {
                print("Could not load data file.")
            }
            
        }
    }
}

struct MyNodeStyleProvider: SphereNodeDataSource {
    func image(for node: SphereNode) -> Image? {
       
    let name = [ "ic_game",
                 "ic_moto",
                 "ic_fiesta",
                 "ic_shop",
                 "ic_drink",
                 "ic_holi",
                 "ic_music",
                 "ic_sport"].randomElement( ) ?? ""
       return Image(name)
           
    }

    func color(for node: SphereNode) -> Color {
        
        let hash = node.id.hashValue
         
        switch abs(hash % 4) {
            case 0:
            return .blue
        case 1:
            return .green
        case 2:
            return .yellow
        case 3:
            return .red
        default:
            return .orange
        }
        
    }
}


// HexMapView<EmptyView>()

#Preview {
    ContentView()
}
