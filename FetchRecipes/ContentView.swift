//
//  ContentView.swift
//  FetchRecipes
//
//  Created by SeanHuang on 12/29/24.
//

import SwiftUI
import RecipeLibrary


struct ContentView: View {
    var vm = RecipeListViewModel(services: ServiceFactory.get(service: "production"))
    var body: some View {
        VStack {
            List{
                ForEach(vm.recipes ,id: \.uuid){recipe in
                    Rectangle().frame(width: 100, height: 100).overlay{
                        if let detail = vm.recipeDetails[recipe.uuid]{
                            Text("Detail: \(recipe.uuid)")
                        }else{
                            Text("Hello \(recipe.uuid)")
                        }
                    }
                }
            }
        }.task{
            vm.getAllRecipes()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
