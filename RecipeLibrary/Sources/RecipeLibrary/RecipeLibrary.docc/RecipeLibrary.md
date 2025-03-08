# ``RecipeLibrary``
This is a library package for fetching recipes provided by Fetch. It was developed through TDD approach with MVVM app architecture.
## Steps to Run the App
To run the app, build the app with target set to a simulator or a physical iOS device.

## Focus Areas:
I focused on these areas beacuse I tried to learn the pattern of what make a good iOS app. All three of these focuses improve the maintainability and extensibility of the code, and I agree with that Swift concurrency is the modern approach and it needs some more digging to its full potential.
- Architecture: Good and clear architecture can bring the overhead down in future. It allows good extendability and ergonomics for smooth development. This project is mainly using MVVM architecture. 
    - Model: 
        All recipes in the file ``RecipeModel``.swift
    - ViewModel: 
        RecipeListViewModel is the vm displaying all the  Recipes.
        RecipeViewModel is not used but extendable for individual interactive Recipes
    - View: (Depends on the app, here we have ContentView in FetchRecipes)
- Performance with Actor and Concurrency:
    - Actors are classes that guarantee serializability in its function calling and state changes. Other than MainActor, all actors share the concurrent threads which Swift runtime allocates for them. Since Swift concurrency guarantees that there will always be task items executed to make sure progress will always be made, all actors will try to finish their tasks at hand when the tasks are resumable. Therefore, if we make MainActor, the main thread, to await for all the download tasks to finish, the Main (actor)thread will be overwhelmed when hundreds of tasks are finished around the same time and wait to finish all the resumable tasks at hand.
    - So a natural design decision was made to offload those tasks from MainActor(i.e. main thread). When they are finished, they can be further processed by cache actors for serialized cache finding. There was a video covered on ``taskGroup`` with a for loop waiting for tasks added and finished, so I took that idea and used ``AsyncSequence`` to achieve the same effect, only this time there is no known number of tasks added beforehand. 
        It needs to be mentioned that because we are using actors, more constraints on types are required for actors to send object messages across actor boundaries.
- Dependency Injection: Inversion of dependency can suit the need for testing as you can define what dependency to use at differnt test cases and even change to during runtime. It increases flexibility and testability.
    - Service Layer for separation of concern and clean architecture.
    - Function as dependency in place of object allows Factory pattern for flexible prebuilt dependency sets.
## Time Spent:
About 10 days.(What a shocker, I know) With me only having  a rough idea of MVVM and testing in the beginning, I tried to figure out what's the best way to design and implement performant code with Swift concurrency. I could not find any covered tutorial or wwdc video on how to implement the architecture I wrote (round trip between MainActor and Cache actors). But I guess thanks to Swift's good design, and the knowledge from wwdcs' Swift concurrency talks, I managed to figure it out.

I spent the first couple of hours setting up MVVM architecture and thinkig about what should be tested and how to be the most data/memory efficent way of writing concurrent code. I admit that I did not fully-understand what Swift concurrecny is. And for the rest of the days, I did a lot of trial and error, and binged watching wwdcs' videos. During the process I tried to use more well-known patterns such Combine's publish-subscribe pattern and completion handler by passing them around but they all seems to not fit in Swift concurrency models, as both need to meet the Sendable protocol requirements, not to mention that neither of them are using actor isolation with Swift concurrency but GCD's dispatch queue for thread concurrency.
## Trade-offs and Decisions:
- Using LazyStack vs **List + NSCache**: By default, ``Lazy Stack`` when combined with ``ScrollView``s are able to load all the subviews progressively as it scrolls. But all the previously loaded content will be stored and accumulated in the memory as well. The available memory for an app will be at the mercy of content provided. Using **List with NSCache** with defined limits will need to reload the content but will only use allocated memory.  And since there is a limited number of items a List can present at a time before deallocations, we don't need to worry about stack overflow but this require more handling to make sure the UI thread can behave smoothly. <br>
    
    Memory usage with NSCache as a base line after slow scrolling:
    ![NSCache](NSCache)
    - NSCache will keep growing until the set limits are hit before eviction. And network fetching is required again.
    Memory usage with DiskCache as an improvement after slow scrolling:
    ![DiskCache](DiskCache)
    -  When list elements disappear, there are fluctuations of memory when ``RecipeDetail`` is removed from vm's ``RecipeListViewModel``'s dictionary. But the overall memory remained stable throughout a long period of scrolling because of disk cache. There are still  sudden rises of memory usage possibly due to how Swift is handling actor's runningTasks' reserved capacity when the scrolling is too fast causing a lot of new adds to the set before old ones could finish. 
    
    
- Using function group vs swappable objects as dependencies: Usually when testing with mock objects, one could go with creating as many mock classes as the scenarios needed. But whenever there is a new functionality to be tested, one has to add functions to all the mock classes with a lot of margins for error, and time consumption. Declaring tuples of functions or Sendable struct of static functions as dependencies can reduce the amount of code written and with great flexibility(say you only want part of the dependencies to be mocked). Yet this will face a challenge when dependencies require states in an async environment, then mock object classes are more suitable.
## Weakest Part of the Project: 
- I wanted to abstract logical code components and make them reusable. But it became increasingly hard when I tried to abstract 2 types of caches for VM. The reason is that because I am using actors, I cannot use castable inheritance nor does protocol  support this and you need concrete types when you are receiving retrieved values from cache. It requires a lot of type coercion which is doing more harm than good. In reality, it's likely there will be only 1 type of cache needed at all times.
- I admit UI is not my best strength. And there is still noticeable lag when testing with a large sample. Also the refresh animation could be made smoother. But I think optimizations can be done with backend supporting pagination and frontend supporting debouncing. 
## Additional Information:
4-5 hours of design + implementation recommended time is still stressful. Almost impossible for people who are exploring the best patterns, and wanting to do a full write-up. I hope that there are brownie points for people who knew little from the beginning and figured it out in the end. 
## Testing 
- Test cases were included in ``RecipeLibraryTests``, they were made to test behaviors for edge cases.
- Simply run test cases written when the package is included(copied) into app's inner structure. (Instead of package dependency at the bottom of navigator) Be aware that a lot of testcases are there to test data fetching capabilities, not a lot of automated correctness detection.

