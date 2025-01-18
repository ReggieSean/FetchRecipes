//
//  File.swift
//  RecipeLibrary
//
//  Created by SeanHuang on 12/30/24.
//

import Foundation
import SwiftUI

/// Service dependencies for fetching recipes with swift concurrency
/// we could only do this because the functions are static or stateless so no race condition. Use actor if we need to modify states.
@available(iOS 16.0, *)
public typealias RecipeService = (allRecipes: @Sendable () async ->[RecipeModel], downloadImage: @Sendable (String) async -> UIImage)

//@available(iOS 16.0, *)
//public struct RecipeService{
//        var allRecipes : @Sendable () async ->[RecipeModel]
//        var downloadImage : @Sendable (String) async -> UIImage
//    public init(allRecipes: @escaping @Sendable () -> [RecipeModel], downloadImage: @escaping @Sendable (String) async -> UIImage) {
//        self.allRecipes = allRecipes
//        self.downloadImage = downloadImage
//    }
//    
//}

extension String{
    static let allRecipes: String = "https://d3jbb8n5wk0qxi.cloudfront.net/recipes.json"
}

/// Production Service dependencies
@available(iOS 16.0, *)
class ProductionRecipeService: AsyncDebugLogger{
    
  
    
    public static func getAllRecipes() async -> [RecipeModel]{
        do{
            if let models : RecipeModelList = try await APIManager.sendHTTPRequestForJSON(url: URL(string: .allRecipes)!, method: .get, body: nil,
                                                                                     headers: {request in request.setValue("application/json", forHTTPHeaderField: "Content-Type")}){
                return models.recipes
            }
        }catch{
            printF("Error Getting All Recipes")
        }
        return []
    }
   
    public static func downloadImage(url: String) async -> UIImage{
        do{
            if let image : UIImage = try await APIManager.sendHTTPRequestForData(url: URL(string: url as String)!, method: .get, body: nil,
                                                                            headers: {request in request.setValue("application/json", forHTTPHeaderField: "Content-Type")}
                                                                            ,dataConverter: { data in  return  UIImage(data: data)!})
            {
                    return image
            }
            
        } catch{
            print("Download error for url:\(url)")
        }
        return  UIImage(named: "404.png", in: .module, with: nil)!
    }
}





/// Mock Service dependencies with simlations
@available(iOS 16.0, *)
public class MockRecipeService : AsyncDebugLogger{
    //content mock
    ///Simulate ideal Receipes Fetching
    public static func getAllRecipes() -> [RecipeModel]{
        if let url = Bundle.module.url(forResource: "sample", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
//                printF("Here")
                let recipeList =  try JSONDecoder().decode( RecipeModelList.self, from: data)
//                printF("THere")
//                let recipes : [RecipeModel] = dataArray.compactMap{data in
//                    do{
//                        return try JSONDecoder().decode(RecipeModel.self, from: data)
//                    } catch{
//                        printF("skipping invalid data")
//                        return nil
//                    }
//                }
                for recipe in recipeList.recipes{
                    printF("Recipe: \(recipe)")
                }
                return recipeList.recipes
            } catch {
                printF("Error: \(error)")
                return []
            }
        }else{
            printF("Error: Cannot load resource url")
            return []
        }
    }
 
    ///When endpoint return an empty array of recipe
    public static func getAllButEmptyRecipes() ->[RecipeModel]{
        return []
    }
    
    ///When backend is not providing valid recipe fields, test if your decoder works
    public static func getMalformedRecipes() -> [RecipeModel]{
        if let url = Bundle.module.url(forResource: "malformed", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let recipeList =  try JSONDecoder().decode( RecipeModelList.self, from: data)
                return recipeList.recipes
            } catch {
                printF("Error: \(error)")
                return []
            }
        }
        printF("Error: Cannot load resource url")
        return []
    }
   
    /// Only suitable for UI test since the time out is too long
    public static func downloadImageWithTimeout(url:  String = "") async -> UIImage{
        do{
                let randomInt = Int.random(in: 1...100) // Random integer between 1 and 100
                if randomInt <= 90{
                    let sleepTime = min(randomInt, 3)
                    do{try await Task.sleep(for: .seconds(sleepTime))}
                    catch{}
                    printF("Random Time out on \(url) sleeped for \(sleepTime) seconds")
                    return UIImage(named: "404.png", in: .module, with: nil)!
                }else{
                    if let image : UIImage = try await APIManager.sendHTTPRequestForData(url: URL(string: url as String)!, method: .get, body: nil,
                                                                                      headers: {request in request.setValue("application/json", forHTTPHeaderField: "Content-Type")}
                                                                                      ,dataConverter: { data in  return  UIImage(data: data)! })
                    {
                        printF("Got Concrete image from \(url)")
                        return image
                    }
                }
        } catch{
            print("Download error for url:\(url)")
        }
        
        return  UIImage(named: "404.png", in: .module, with: nil)!
    }
}
