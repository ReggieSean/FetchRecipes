//
//  ContentView.swift
//  FetchRecipes
//
//  Created by SeanHuang on 12/29/24.
//

import SwiftUI
import RecipeLibrary


struct ContentView: View {
    
    @ObservedObject var vm : RecipeListViewModel
    init(){
        if CommandLine.arguments.contains("--mock"){
            print("Mock service")
            self.vm = RecipeListViewModel(services: ServiceFactory.get(service: "mock"))
        } else if CommandLine.arguments.contains("--malformed"){
            print("Malformed service")
            self.vm = RecipeListViewModel(services: ServiceFactory.get(service: "malformed"))
        }else {
            print("Production service")
            self.vm = RecipeListViewModel(services: ServiceFactory.get(service: "production"))
        }
    }
    var body: some View {
        VStack {
            List{
                ForEach(vm.recipes ,id: \.uuid){recipe in
                    let recipeDetail = vm.recipeDetails[recipe.uuid]!
                    HStack{
                        Rectangle().frame(width: 100, height: 100).overlay{
                            if let img = recipeDetail.smallImage{
                                Image(uiImage: img )
                            }
                        }
                        Text("\(recipeDetail.uuid)")
                    }.onAppear{
                        vm.getRecipe(recipe: recipe)
                    }
                }
            }
        }.task{
            await vm.getAllRecipes().value
            print("Got all recipes")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
