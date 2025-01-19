# ``RecipeLibrary``

This is a library package for fetching recipes provided by Fetch. It was developed through TDD approach with MVVM app architeture.


## Steps to Run the App
To run the app, build the app with target set to a simulator or a physical iOS device.
To run test cases without UI
    - navigate to this package's directory and run "swift test" to test all cases or use Xcode's built in GUI to activate individual testcases.
    - Or simply run test cases written when the package is included(copied) into app's inner strucuture. (Instead of package dependency at the bottom of navigator)

## Focus Areas:
What specific areas of the project did you prioritize? Why did you choose to focus on these areas?
- Architecture: Good and clear architecture can bring the overhead down in future. It allows good extendability and and ergonomics for smooth development. This project is mainly using MVVM architecture. 
    - Model: 
        All recides in the file ``RecipeModel``.swift
    - ViewModel: 
        RecipeListViewModel is the vm displaying all the  Recipes.
        RecipeViewModel is not used but extendable for individual interactive Recipes
    - View: (Depends on the app, here we have ContentView in FetchRecipes)
- Performance with Actor and Concurrency:
    - Actors are classes that guarantees serializability in its function calling and state changes. Other than MainActor, all actors share the concurrent threads which swift runtime allocates for them. Since swift concurrency guarantees that there will always be task items executed to make sure progresses will always be made, all actors will try to finish their tasks at hand when the tasks are resumable. Therefore, if we make MainActor, the main thread, to await for all the download tasks to finish, the Main (actor)thread will be overwhelmed when hundreds of tasks are finished around the same time and wait to finish all the resumable tasks at hand.<>
    - So a natural design decision was made to off load those tasks from MainActor(i.e. main thread). When they are finished, they can be further processed by cache actors for serialized cache finding. There was a video covered on ``taskGroup`` with a for loop waiting for tasks added and finished, so I took that idea and used ``AsyncSequence`` to achieve the same effect, only this time there is no known number of tasks added beforehand. 
        It needs to be mentioned that because we are using actors, more constraint on types are required for actors to send object messages across actor boundaries.

- Dependency Injection: Inversion of dependency can suits the need for testing as you can define what dependency to use at run time and compile time. It increases flexibility and testability.
    - Service Layer for separation of concern and clean architecture.
    - Fuction as dependency in place of object allows Factory pattern for flexible prebuilt dependency sets.



## Time Spent:

About 10 days. With me only having  a roungh idea of MVVM and testing in the beginning, I tried to figure out what's the best way to design and implement performant code with Swift concurrency. There was no covered tutorial or wwdc video on how to implement the architecture I designed (round trip between MainActor and Cache actors). But I guess thanks to Swift's good design, I managed to figure it out. During the process I tried to use more well-known patterns such Combine's publish-subscribe pattern and completion handler by passing them around but they all seems to not fit in Swift concurrency models, as both need to meet the Sendable protocol requirements, not to mention that it is hard to implement a referencing process.

## Trade-offs and Decisions:
- Using LazyStack vs **List + NSCache**: By default, ``Lazy Stack`` when combined with ``ScrollView``s are able to load all the subviews progressively as it scroll. But all the previously loaded contetn will be stored and accumulated in the memory as well. The available memory for an app will be at the mercy of content provided. Using **List with NSCache** with defined limits will need to reload the content but will only use allocated memory.  And since there is a limited number of items a List can present at a time before deallocations, we don't need to worry about stack overflow but this require more handling to make sure the UI thread can behave smoothly. 
- Using function group vs swappable objects as dependencies: Usually when testing with mock objects, one could go with creating as many mock classes as the scenarios needed. But whenever there is a new functionality to be tested, one have to add functions to all the mock classes with a lot of margins for error, and time comsumption. Declaring tuple of functions or Sendable struct of static functions as depdendencies can reduce the amount of code written and with great flexibility(say you only want part of the dependencies to be mocked). Yet this will face a challenge when dependencies require states in an async environment, then mock object classes are more suitable.





## Weakest Part of the Project: 
- I wanted to abstract logical code components and made them reusable. But it became increasing hard when I tried to abstract 2 types of caches for VM. The reason is that because I am using actor, I cannot use castable inheritance nor does protocol  support this and you need concerete types when you are receiving retreived values from cache. It requrires a lot of type coercion which is making more harm than good. In reality, it's likely there will be only 1 type of cache needed at all times.
- I admit UI is not in my best strength. And there is still noticable lag when testing with a large sample. Also the refresh animation could be made smoother. But I think optimizations can be done with backend supporting pagination and frontend supporting debouncing.

## Additional Information:
4-5 hours of design + implementation time is crazy. Not less stressful than a leetcode style for people who are serious. 

## Testing 
- Test cases were included in ``RecipeLibraryTests``, they were made to test behaviors for edge cases.

