//
//  File.swift
//  RecipeLibrary
//
//  Created by SeanHuang on 1/7/25.
//

import Foundation
import SwiftUI
import Combine

//String are not Objects because they are value type, so a wrapper that's not modifiable is needed here
final class CacheKey: AnyObject, Sendable, Hashable, CustomStringConvertible{
    let key: String
    func hash(into hasher: inout Hasher) {
            hasher.combine(key)
    }
        
    static func == (lhs: CacheKey, rhs: CacheKey) -> Bool {
        return lhs.key == rhs.key
    }
    init (key: String){
        self.key = key
    }
    var description: String {
        return "\(key)"
    }
}

@MainActor public class RecipeListViewModel : ObservableObject, AsyncDebugLogger{
    
    let services : RecipeService
//    var cache : any AsyncCache
//    var cache: CacheTaskManager<CacheKey , RecipeDetail> =  CacheTaskManager<CacheKey , RecipeDetail>(maxTasks: 10, cacheCostLimit: 5000, cacheCountLimit: 200)
    var cache: FileTaskManager<CacheKey, RecipeDetail> = FileTaskManager(maxTasks: 10, cacheCostLimit: 100,cacheCountLimit: 100)
    var pipeFromCache : AsyncStream<(CacheKey, RecipeDetail)>?
    var loop : Task<Void, Never>?
    @Published public var recipes : [RecipeModel] = []
    @Published public var recipeDetails : [String: RecipeDetail] = [:]
    
    var images : [CacheKey : UIImage] = [:]
    
    /// RecipeListViewModel initializer, implicity acync due to cache limiter actor's initialization
    /// - Parameters:
    ///   - services: RecipeSerivce dependency tuples(stateless)
    public init(services: RecipeService){
        self.services = services
    }
    
    deinit{
        self.loop?.cancel()
    }
    
    //2 choices when updating @Published on MainActor
    //1. Using MainActor for incremental updates, good for swiftui diffing.
    //2. Using another actor and sync between mainactor and that actor with a sendable await fuction
    //That will cause performance issue when copying large tasks.
    ///start looping and prepare for cahce to update Published variable
    public func startCache() async {
        self.pipeFromCache = await cache.startChannel()
        self.loop = Task{
            printF("Loop Started")
            for await detailKV in self.pipeFromCache! {
                printF("Received k:\(detailKV.0.key) v:\(detailKV.1)")
                self.recipeDetails[detailKV.0.key] = detailKV.1
            }
            //at main actor for logging, so serialized by default
            printF("Stopped cache receiving loop at deinit")
        }
    }
    
    public func flushCache(){
        self.loop?.cancel()
//        self.cache = CacheTaskManager<CacheKey,  RecipeDetail>(maxTasks: 10, cacheCostLimit: 5000, cacheCountLimit: 200)
        self.cache = FileTaskManager(maxTasks: 10, cacheCostLimit: 100,cacheCountLimit: 100)
    }
   
    public func getAllRecipes() -> Task<Void, Never>{
        return Task{
            await self.startCache()
            //valid recipes with required fields
            let recipes =  await services.allRecipes()
            self.recipes = recipes
            //adding stub models before recipe detail are received
            for recipe in self.recipes{
                self.recipeDetails[recipe.uuid] = RecipeDetail(uuid: recipe.uuid ,bigImage: nil, smallImage: nil)
            }
        }
    }
    
    //store a publisher to update recipeDetail
    //You could only use a Task to update the details in viewmodel for UI, but you can't manipulate the output of the Task to cached images unless you either :
    //      1.call a separte function
    //      2.capture cache in the Task.(now cache has reference of tasks and tasks have reference of cache, you have to finish canceling all tasks before you could deinit cache. Bit dangerous!)
    // ulternatively,
    //      1.pass in the publisher and task all together and let cache to decide (now only cache is holding references of tasks and publishers)
    //      2.pass in the service dependencies and let cache to return a publisher being able to recive cancellation events in order to cancel tasks started by cache(the dependencies will be contained in the publishers, cancelable through subscribtion, and cache can deinit and cancel all the tasks), but still, we need to get hold of the publisher and the task so that I could either publish immediately or use task to update cache and publish result. (Not able , since publisers are not able to cross actors
    //      3.use asyncstream and a task to wait and update UI
    
    //Sendable?
    //update cycle for publishers?
    
    //crossing from main actor to cache actor, is implicit async so we need small tasks to run actor isolated functions
    //The async nature of Task limiter, and sync nature of Cache makes them very hard to be combined.
// This function is being called by MainActor so any variable can be referenced
    public func getRecipe(recipe : RecipeModel) -> Task<Void, Never>{
        let uuid = recipe.uuid
        let smallURL = recipe.smallPhotoURL
        let bigURL = recipe.largePhotoURL
        //This task will inherit MainActor context first because SwiftUI will call getRecipe
        //async let, withTaskGroup, Task{}, and Task.detached{} start tasks immediately
        //You cannot bind the Task concurrent context with async let and send the Task with current context, async let starts tasks immediately
        let cacheFetch : Task<RecipeDetail ,Never> = Task.detached(priority: .background){[downloadImageSerive = services.downloadImage] in
            //if !(await cache.getHit(key: CacheKey(key : uuid))){}
            async let smallPicTask =   await downloadImageSerive(smallURL)
            async let bigPicTask =  await downloadImageSerive(bigURL)
            defer {Self.printF("Finished getting task \(uuid)")}
            return RecipeDetail(uuid: uuid, bigImage: await bigPicTask, smallImage: await smallPicTask)
        }
        
        //It seems I could implement the queue on the caller because the Tasks are self contained, an issue is that if you scroll down really quick and scroll back up, the later initiated task in List/UITableView could finish eariler than the  same task initiated previously. (when backend don't guarantee the synchronous sequnece because of network issues), causing a waste of data.
        //One way to mitigate this is to be able to cancel the re-initiation if a you can detect that previous initiation is set in motion by looping over a task queue and the currently runnign task group. But looping takes O(n) and the time will keep growing if you initiated hundreds of tasks at the same time ( Not ideal for smooth UI scrolling when multiple fetch are done). We could use a design similar to LRU cache, and offload that work to actor, since we can recive stream of RecipeDetails asynchronously from pipeFromCache.
        //Return the cross actor task from Main to actor
        return Task{await cache.addTask(task: (CacheKey(key: recipe.uuid), cacheFetch))}
    }
    
    
}
