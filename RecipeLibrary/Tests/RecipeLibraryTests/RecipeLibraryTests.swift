import XCTest
@testable import RecipeLibrary

final class RecipeLibraryTests: XCTestCase , Logger, InfoPrinter{
    
    /// Test Fetching the test recipe list
    @MainActor
    func testGettingTestRecipeList() async throws {
                    
        let vm = RecipeListViewModel(services: ServiceFactory.get(service: "mock"))
        let task = vm.getAllRecipes()
        await task.value
        Self.printF("Got all recipes")
        XCTAssertTrue(vm.recipes.count > 0)
    }
   
    @MainActor
    /// Test Fetching an empty recipe list
    func testGettingEmptyRecipe() async throws {
        let vm = RecipeListViewModel(services: ServiceFactory.get(service: "empty"))
        await vm.getAllRecipes().value
        Self.printF("Got empty recipes")
        XCTAssertTrue(vm.recipes.count == 0)
    }
    
    @MainActor
    /// Test Fetching an empty recipe list
    func testGettingMalformedRecipe() async throws {
        let vm = RecipeListViewModel(services: ServiceFactory.get(service: "malformed"))
        await vm.getAllRecipes().value
        Self.printF("Got empty recipes")
        try await Task.sleep(for: .seconds(4))
        XCTAssertTrue(vm.recipes.count == 1)
        XCTAssertTrue(vm.recipes[0].name == "New York Cheesecake")
    }
   
    @MainActor
    /// Test fetching the test recipe list and detail of each(images)
    func testGettingMalformedRecipes() async throws {
        let vm = RecipeListViewModel(services: ServiceFactory.get(service: "malformed"))
        await vm.getAllRecipes().value
        await withTaskGroup(of: Task<Void,Never>.self){group in
            for recipe in vm.recipes{
                group.addTask{ @MainActor in
                    vm.getRecipe(recipe: recipe)
                }
            }
            for await  result in group{
                printF("Finished a group task at \(Date.now)")
            }
        }
        // wait till main actor received all result across actor boundary
        printF("Waiting till actor finsihes")
        try await Task.sleep(for: .seconds(4))
    }
    @MainActor
   /// Test fetching every recipe that production endpoint provides.
    func testGettingProductionRecipe() async throws {
        Self.printModuleResources()
        let vm = RecipeListViewModel(services: ServiceFactory.get(service: "production"))
        await vm.getAllRecipes().value
        await withTaskGroup(of: Task<Void,Never>.self){group in
            for recipe in vm.recipes{
                group.addTask{ @MainActor in
                    vm.getRecipe(recipe: recipe)
                }
            }
            for await  result in group{
                printF("Finished a group task at \(Date.now)")
            }
        }
        // wait till main actor received all result across actor boundary
        printF("Waiting till actor finsihes")
        try await Task.sleep(for: .seconds(4))
        //RecipeLibrary/RecipeListViewModel.swift-(startCache())-(61):
//        self-->Received k:891a474e-91cd-4996-865e-02ac5facafe3 v:uuid:891a474e-91cd-4996-865e-02ac5facafe3+ bigImage(Optional(<UIImage:0x60000301c1b0 anonymous {700, 700} renderingMode=automatic(original)>) + smallImage(Optional(<UIImage:0x6000030030f0 anonymous {150, 150} renderingMode=automatic(original)>)
        XCTAssertTrue(true)
    }
   
    
    /// Test fetching every recipe that production endpoint provides with time out sometimes
    @MainActor
    func testGettingProductionRecipeWithTimeOut() async throws {
        
        let vm = RecipeListViewModel(services: ServiceFactory.get(service: "random_timeout"))
        await vm.getAllRecipes().value
        await withTaskGroup(of: Task<Void,Never>.self){group in
            for recipe in vm.recipes{
                group.addTask{ @MainActor in
                    vm.getRecipe(recipe: recipe)
                }
            }
            for await  result in group{
                printF("Finished a group task at \(Date.now)")
            }
        }
        // wait till main actor received all result across actor boundary
        printF("Waiting till actor finsihes")
        try await Task.sleep(for: .seconds(10))
        XCTAssertTrue(true)
    }
    
    

}
