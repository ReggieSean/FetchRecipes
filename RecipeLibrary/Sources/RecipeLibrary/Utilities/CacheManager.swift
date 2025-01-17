//
//  File.swift
//  RecipeLibrary
//
//  Created by SeanHuang on 1/1/25.
//

import Foundation
//import DequeModule
import SwiftUI

public protocol AsyncCache{
    associatedtype K: AnyObject & Hashable & Sendable
    associatedtype V: AnyObject & Sendable
    func addTask(task: (K, Task<V, Never>)) async
    func startChannel() async -> AsyncStream<(K,V)>
}

//https://developer.apple.com/videos/play/wwdc2021/10132/?time=1797
actor CacheTaskManager<K: AnyObject & Hashable & Sendable,V : AnyObject & Sendable> : AsyncCache, AsyncDebugLogger{
 
    typealias CachePair = (K , V)
//    private var currentTaskCount : Int
//    private let maxTasks : Int
    private var runningTasks : Set<K>
//    private var queuedTasks : Set<K> //Only need to know if a task is queued
    private let cache : NSCache<K, V>
    private var pipe : AsyncStream<CachePair>.Continuation?
    
    //private var queue : Deque<(K, Task<V,Never>)>
    
    private var running = false
    
    /// initialize Cache and spin up a task loop in backgroud
    /// - Parameters:
    ///   - maxTasks:
    ///   - cacheCostLimit:
    ///   - cacheCountLimit:
    init(maxTasks: Int, cacheCostLimit: Int, cacheCountLimit: Int){
//        self.maxTasks = maxTasks
//        self.currentTaskCount = 0
        self.runningTasks = []
        //self.queuedTasks = []
        //self.queue =  []
        self.cache = NSCache()
    }

    
   
    ///Create a publisher when the asynchrnously downloaded image is available
    //should you pass in the task and wait till it finishes and get its return value with completion
    // or should you await this function to return the task result when its done.(<- this! because the function passing in have effect on its output, not just a side effect.)
    //passing in service layer closure still make sense:
    //How to deal with canceling the tasks when cache count limit is hit?
    //We don't since they are new tasks not timed-out yet and it will be added to cache when finished
    // if you don’t use a Publisher to notify SwiftUI of updates to downloaded images, you’ll need to maintain a list or dictionary of downloaded images in a class and provide a way for the UI to query for specific images. However, without a Publisher, the UI won’t automatically update when an image becomes available. This means you’ll need to implement a manual mechanism for updating the UI.
  
    //Before Swift concurrency, we uses GCD's queue for micro (light-weight) context switching from a closure to another, this entails the overhead of context switching and priority inversion due to queue's FIFO nature. When tiny tasks are being dispatched to the queue, the time for context switching will catch up to the useful time, because GCD will need to involve some kernel operation to save context in user space and switch to the next. With Swift concurrency, kernel is no longer directly involved, and async fucntions are directly stored on heap, managed by swift's concurrecy runtime. To preserve the serialization of start of execution for asynchronous functions, actors are introduced.
    
    //Like the problem of thread explosion with GCD, when you are overcrowding MainActor with update tasks, you can slow down the UI performance. So it seems ideal to limit the number of concurrent tasks.
    
    //Actors are inherently using their own queue when actor's function are being called. However, the queue only does serialization. We need a mechanism to limit how many tasks are allowed to be executed to reduce the frequency of updating the main actor, i.e. main thread.
    //We could add tasks directly to a queue and use a mechanism to busy-polling from the queue if there is enough remaining quota. But this seems inefficient since it occupies CPU when no tasks are running and a preiodically check would not provide an "instant" UI exeprience.
    //We could use unstructured Tasks for each list item and have a Dictionary here to limit amount of Task being runned concurrently and removed when finished.(Like a taskgroup but not awaited as a whole, but this will not be compatible with debouncing)
    
    //alternatively, a common pattern for limiting concurrecy is to use taskgroup to prepare tasks to execute and create a run loop within it to wait for the signal of completed tasks within the taskgroup, but here you need to have a known number of tasks when dispatching them to the taskgroup. Luckily we have pagination for SwiftUI.
    //And finally, we need to signal when to start a task group since overcrowding will still happen if you let multiple tasks group to run at the same time(User can scroll really fast to bottom) There could be another optimization ,"debouncing", combined with pagination to selective start task groups but I will keep this simple for now.
    
    //one thing about Taskgroup is that although you can have structured concurrency and all that, you have to wait till everything is finished before collecting the result
   // If you are going to control with pagination why would you still need taskgroup for limiting how much tasks you can concurrently/ parallelly execute. I would argue it still helps with performance, and when you have multiple taskmanagers, you can fine-tune how much cache and and compute time you will allocate each for differnt priorities.
    
    //Yet it turns out that because we may need to scroll up and down, using a taskgroup with predefined range beyond or after the start index is undetermined, so it still cannot figure out what is the set of task that need to be run.
    //So as it finally conclude itself, I need to handle the amount of tasks being run through task manager after individual tasks are queued up.
    
// if mannually implementing taskgroup  a call-back is needed to set UI after task finsihed
// since now you cannot rely on taskgroup's return value. This could be done with individual publisher returned immediatedly after adding a task but this will make the code base more complicated.
// This cache's purpose is to give responsive responses to callers using the storage, so it's more logical to let the caller to handle the publishers' life cycle(like canceling the download)
  
    //initially I tried to return anypublihser and let UI to receive update but Anypublisher is not compatible with actor, they are not Sendable across actor spaces.
    //I have to try convert Publishers to async sequence
    
    public func addTask(task: (K, Task<V, Never>)) async {
        if let hit =  cache.object(forKey: task.0){
            printF("cache hit for \(task.0)")
            self.pipe!.yield((task.0, hit))
        }else if !(runningTasks.contains(task.0)){
            runningTasks.insert(task.0)
            printF("added Task for \(task.0)")
            let object = await task.1.value
            cache.setObject(object, forKey: task.0)
            completeTask(key: task.0, result: object)
            runningTasks.remove(task.0)
        }
    }
    
//    /// Use up all the quota for task pool
//    private func runTask(){
//        while currentTaskCount < maxTasks, let newTask = getTaskFromQueue(){
//            Task{
//                let result : V = await newTask.1.value
//                completeTask(key: newTask.0, result: result)
//            }
//        }
//            //initiate task in current actor
//        
//    }
//    private func getTaskFromQueue() -> (K,Task<V, Never>)?{
//        if let current : (K, Task<V, Never>) = queue.first{
//            queue.removeFirst()
//            runningTasks.insert(queuedTasks.remove(current.0)!)
//            currentTaskCount += 1
//            return current
//        }
//        return nil
//    }
    private func completeTask(key: K, result: V){
        self.pipe!.yield((key, result))
    }

    //cannot access AsyncContinuation before fully init
    public func startChannel() -> AsyncStream<(K,V)>{
        return AsyncStream{continuation in
            self.pipe = continuation
        }
    }
   
//    public func getHit( key : K) -> Bool{
//        if let hit =  cache.object(forKey: key){
//            self.pipe!.yield((key, hit))
//            return true
//        }
//        return false
//
//    }
   
    
}

///// A TaskQueue to limit maximum tasks that could be concurrently executed.
//struct TaskQueue<T> : AsyncSequence {
//    
//    typealias AsyncIterator = AsyncStream<T>.Iterator
//    typealias Element = T
//    private var continuation: AsyncStream<T>.Continuation?
//    private let stream : AsyncStream<T>
//    private let maxConcurrent: Int
//    init(maxConcurrent: Int) {
//        self.continuation = continuation
//        self.stream = AsyncStream(unfolding: continuation)
//        self.maxConcurrent = maxConcurrent
//    }
//    
//    func makeAsyncIterator() -> AsyncIterator {
//        return stream.makeAsyncIterator()
//    }
//
//    
//}
actor FolderCount{
    static private var counterPart = 0
    static var counter: Int {
        let current = counterPart
        counterPart += 1
        return current
    }
}
//Creating this abstract version of file cache increases the complexity of managing serialization when saving and fetching from disk.
actor FileTaskManager<K: AnyObject & Hashable & Sendable,V : AnyObject & Sendable & Codable> : AsyncCache, AsyncDebugLogger{
    typealias FilePair = (K , V)
    private var runningTasks : Set<K>
    private var pipe : AsyncStream<FilePair>.Continuation?
    private let folder: String

    
    init(maxTasks: Int, cacheCostLimit: Int, cacheCountLimit: Int) {
        self.runningTasks = []
        self.folder = "filecache_\(Date.now.hashValue)_\(FolderCount.counter)"
        self.createFolder()
    }
    
    deinit{
        do {
            guard let path = folderPath()else {
                printF("Filecache deinit failed to locate folder CachePath:\(folder)")
                return
            }
            try FileManager.default.removeItem(at: path)
        }catch let error{
            printF("Filecache deinit failed: \(error)")
        }
    }
   
    //Function will only be called once during init, no risk of race
    nonisolated private func createFolder(){
        guard let url = folderPath() else {return}
        if !FileManager.default.fileExists(atPath: url.path){
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
                printF("Created folder at \(url.path)")
            } catch let error{
               printF("Error when creating cache folder")
            }
        }else{
            //in the rare case when some other apps created that folder
            printF("cache folder already exists")
        }
    }
    
    //Function will only be called once during init, no risk of race
    nonisolated private func folderPath() -> URL?{
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent(folder)
    }
    
    private func cachePath(key: K) -> URL?{
        guard let folder = folderPath() else{
            return nil
        }
        return folder.appendingPathComponent(String(describing: key))
    }
    
    private func getCache(forKey key: K) -> V?{
        guard
            let url = cachePath(key: key),
            FileManager.default.fileExists(atPath:  url.path) else{return nil}
        return try? JSONDecoder().decode(V.self, from: Data(contentsOf: url))
    }
    
    private func saveCache(object: V, forKey key: K){
        guard let url = cachePath(key: key) else{return}
        do {
            try JSONEncoder().encode(object).write(to: url)
        } catch let error{
            printF("Error when saving cache \(error)")
        }
    }

    
    public func addTask(task: (K, Task<V, Never>)) async {
        if let hit =  getCache(forKey: task.0){
            printF("cache hit for \(task.0)")
            self.pipe!.yield((task.0, hit))
        }else if !(runningTasks.contains(task.0)){
            runningTasks.insert(task.0)
            printF("added Task for \(task.0)")
            let object = await task.1.value
            saveCache(object: object, forKey: task.0)
            completeTask(key: task.0, result: object)
            runningTasks.remove(task.0)
        }
    }
    
    private func completeTask(key: K, result: V){
        self.pipe!.yield((key, result))
    }

    //cannot access AsyncContinuation before fully init
    public func startChannel() -> AsyncStream<(K,V)>{
       
        return AsyncStream{continuation in
            self.pipe = continuation
        }
    }
}
