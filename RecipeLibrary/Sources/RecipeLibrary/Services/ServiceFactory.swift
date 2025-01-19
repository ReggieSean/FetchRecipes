//
//  File.swift
//  RecipeLibrary
//
//  Created by SeanHuang on 12/31/24.
//

import Foundation

///Reterive mock, or production networking dependencies
public class ServiceFactory {
    private init(){}
    static public func get(service: String = "production") -> RecipeService{
        switch service {
            case "production":
                return  RecipeService(allRecipes: ProductionRecipeService.getAllRecipes, downloadImage:  ProductionRecipeService.downloadImage)
            case "mock":
                return RecipeService(allRecipes: MockRecipeService.getAllRecipes, downloadImage: ProductionRecipeService.downloadImage)
            case "2000_mock":
                return RecipeService(allRecipes: MockRecipeService.getALotOfRecipes, downloadImage: ProductionRecipeService.downloadImage)
            case "empty":
                return RecipeService(allRecipes: MockRecipeService.getAllButEmptyRecipes, downloadImage: ProductionRecipeService.downloadImage)
            case "malformed":
                return RecipeService(allRecipes: MockRecipeService.getMalformedRecipes , downloadImage: ProductionRecipeService.downloadImage)
            case "random_timeout":
                return RecipeService(MockRecipeService.getAllRecipes,  MockRecipeService.downloadImageWithTimeout)
            default:
                return  RecipeService(allRecipes: ProductionRecipeService.getAllRecipes, downloadImage: ProductionRecipeService.downloadImage)
        }
    }

}
