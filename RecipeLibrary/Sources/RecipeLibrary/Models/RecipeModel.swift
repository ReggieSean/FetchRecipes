//
//  File.swift
//  RecipeLibrary
//
//  Created by SeanHuang on 12/31/24.
//

import Foundation
import SwiftUI
import Combine

///temporary Json contianer holder to skip invalid Recipe
public class RecipeModelList: Codable, AsyncDebugLogger{
    var recipes: [RecipeModel]
    required public init(from decoder: any Decoder) throws{
        let container  = try decoder.container(keyedBy: CodingKeys.self)
        self.recipes = []
        var recipesArray = try container.nestedUnkeyedContainer(forKey: .recipes) // Access nested array
        while !recipesArray.isAtEnd{
            do{
                let rec = try recipesArray.decode(RecipeModel.self)
                recipes.append(rec)
            } catch{
                printF("Skipping an invalid recipe")
            }
        }
    }
    private enum CodingKeys: String, CodingKey {
        case recipes
    }
}


public final class RecipeModel : Codable, Sendable, CustomStringConvertible, AsyncDebugLogger{
    public var description: String {
        return "\(name),\(cuisine),\(uuid)|\n \(smallPhotoURL),\(largePhotoURL),\(sourceURL),\(youtubeURL)"
    }
    
    let cuisine: String
    let name: String
    let smallPhotoURL: String
    let largePhotoURL: String
    let sourceURL: String
    let youtubeURL: String
    public let uuid: String
    

    enum CodingKeys: String, CodingKey {
        // Required Keys
        case cuisine    ///The cuisine of the recipe.
        case name    ///The name of the recipe.
        case uuid    ///The unique identifier for the receipe. Represented as a UUID.
        /// Optional Keys
        case largePhotoURL = "photo_url_large"    ///The URL of the recipes’s full-size photo.
        case smallPhotoURL = "photo_url_small"    ///The URL of the recipes’s small photo. Useful for list view.
        case sourceURL = "source_url"    ///The URL of the recipe's original website.
        case youtubeURL = "youtube_url"    ///The URL of the recipe's YouTube video.
    }
    
    init(cuisine: String, name: String, uuid: String , smallPhotoURL: String = "", largePhotoURL: String = "", sourceURL: String = "", youtubeURL: String = "") {
        self.cuisine = cuisine
        self.name = name
        self.uuid = uuid
        self.smallPhotoURL = smallPhotoURL
        self.largePhotoURL = largePhotoURL
        self.sourceURL = sourceURL
        self.youtubeURL = youtubeURL
    }
   
    /// Return an empty recipe when a receipe received is not valid
    required public convenience init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let name = try container.decode(String.self, forKey: .name)
            let uuid = try container.decode(String.self, forKey: .uuid)
            let cuisine = try container.decode(String.self, forKey: .cuisine)
            let largePhotoURL = try? container.decodeIfPresent(String.self, forKey: .largePhotoURL) ?? ""
            let smallPhotoURL = try? container.decodeIfPresent(String.self, forKey: .smallPhotoURL) ?? ""
            let sourceURL = try? container.decodeIfPresent(String.self, forKey: .sourceURL) ?? ""
            let youtubeURL = try? container.decodeIfPresent(String.self, forKey: .youtubeURL) ?? ""
            self.init(cuisine: cuisine, name: name, uuid: uuid, smallPhotoURL: smallPhotoURL!, largePhotoURL: largePhotoURL!, sourceURL: sourceURL!,youtubeURL: youtubeURL!)
            //self.init(cuisine: "Empty", name: "Empty", uuid: "Empty")
    }
        
}


final public class RecipeDetail : Sendable, Equatable, Codable,CustomStringConvertible, AsyncDebugLogger{
    let uuid : String
    let bigImage :UIImage?
    let smallImage: UIImage?
    public var description: String{
        return "uuid:\(uuid)+ bigImage(\(String(describing: bigImage)) + smallImage(\(String(describing: smallImage))"
    }
    
    init(uuid: String,bigImage:  UIImage, smallImage: UIImage) {
        self.uuid = uuid
        self.bigImage = bigImage
        self.smallImage = smallImage
    }
    
    static public func == (lhs: RecipeDetail, rhs : RecipeDetail) -> Bool{
        return lhs.uuid == rhs.uuid
    }
    enum CodingKeys : String, CodingKey {
        case uuid
        case bigImage
        case smallImage
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uuid = try container.decode(String.self, forKey: .uuid)
            
        if let bigImageData = try container.decodeIfPresent(Data.self, forKey: .bigImage) {
            self.bigImage = UIImage(data: bigImageData)
            
        }else {
            self.bigImage = nil
        }
            
        if let smallImageData = try container.decodeIfPresent(Data.self, forKey: .smallImage) {
            self.smallImage = UIImage(data: smallImageData)
        }else{
            self.smallImage = nil
        }
        return
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        if let bigImage = bigImage, let bigImageData = bigImage.pngData() {
            try container.encode(bigImageData, forKey: .bigImage)
        }
        if let smallImage = smallImage, let smallImageData = smallImage.pngData() {
            try container.encode(smallImageData, forKey: .smallImage)
        }
    }
    
}
