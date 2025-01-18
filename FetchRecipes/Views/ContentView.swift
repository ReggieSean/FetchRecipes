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
    
    @State var popUp : Bool = false
    @State var selectedRecipe : RecipeModel? = nil
    var body: some View {
        NavigationStack{
            VStack {
                List{
                    ForEach(vm.recipes ,id: \.uuid){recipe in
                        if let recipeDetail = vm.recipeDetails[recipe.uuid]{
                            Button(action: {
                                selectedRecipe = recipe
                                popUp = !popUp
                            }){
                                HStack{
                                    Rectangle().frame(width: 100, height: 100).overlay{
                                        if let img = recipeDetail.smallImage{
                                            Image(uiImage: img)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipped()
                                        }
                                    }
                                    VStack(alignment: .leading){
                                        Text("\(recipe.name)")
                                        Text("\(recipe.cuisine)")
                                    }
                                    
                                }.onDisappear{
                                    vm.recipeDetails[recipe.uuid] = nil
                                }
                            }.foregroundStyle(.black)

                        }else{
                            HStack{
                                Rectangle().frame(width: 100, height: 100)
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
            .sheet(isPresented: $popUp){
                VStack(alignment: .leading){
                    Button("Close"){
                        popUp.toggle()
                    }.padding(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                    
                    Text("\(selectedRecipe?.name ?? "")")
                    Text("\(selectedRecipe?.cuisine ?? "")")
                    Text("Youtube:\(selectedRecipe?.youtubeURL ?? "")")
                    Text("Source:\(selectedRecipe?.sourceURL ?? "")")
                    Spacer()
                }
            }
        }.navigationTitle("Recipes")
        
    }
}

#Preview {
    ContentView()
}
