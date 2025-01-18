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
                    if let recipeDetail = vm.recipeDetails[recipe.uuid]{
                        HStack{
                            Rectangle().frame(width: 200, height: 200).overlay{
                                if let img = recipeDetail.smallImage{
                                    Image(uiImage: img )
                                }
                            }
                            VStack{
                                Text("\(recipe.name)")
                                Text("\(recipe.)")
                            }
                            
                        }.onDisappear{
                            vm.recipeDetails[recipe.uuid] = nil
                        }
                    }else{
                        HStack{
                            Rectangle().frame(width: 200, height: 200)
                            Text("Fetching \(recipe.name)")
                        }.onAppear{
                            vm.getRecipe(recipe: recipe)
                        }
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
