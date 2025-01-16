//
//  File.swift
//  RecipeLibrary
//
//  Created by SeanHuang on 12/31/24.
//

import Foundation
import SwiftUI


public class RecipeViewModel : AsyncDebugLogger{
    var detail : RecipeDetail
    
    public init(detail : RecipeDetail) {
        self.detail = detail
    }
}
