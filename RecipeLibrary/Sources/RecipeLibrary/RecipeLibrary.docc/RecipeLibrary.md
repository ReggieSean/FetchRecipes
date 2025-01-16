# ``RecipeLibrary``

This is a library package for fetching recipes provided by Fetch. It was developed through TDD approach resulting in an architeture that will allow MVVM app architeture


## Steps to Run the App
To run the app, build the app with target set to a simulator or a physical iOS device.
To run test cases without UI, navigate to this package's directory and run "swift test" to test all cases or use Xcode's built in GUI to activate individual testcases.
## Focus Areas:
What specific areas of the project did you prioritize? Why did you choose to focus on these areas?
- Architecture: Good and clear architecture can bring the overhead down in future. It allows good extendability and and ergonomics for smooth development. This project is mainly using MVVM architecture. 
    - Model:
    - ViewModel:
    - View: 
- Dependency Injection: Inversion of dependency can suits the need for testing as you can define what dependency to use at run time and compile time. It increases flexibility and testability.
    - Service Layer for separation of concern and clean architecture.
    - Fuction as dependency in place of object allows Factory pattern for prebuilt dependency sets.
- Testing: In the begining developer creates the UI and actions to interact with. 
    - Receiving valid receipe:
    - Receiving empty receipe:
    - Receiving corrupted receipe:


## Time Spent:
Approximately how long did you spend working on this project? How did you allocate your time?

## Trade-offs and Decisions:
- Using LazyStack vs List + NSCache: By default, ``Lazy Stack`` when combined with ``ScrollView``s are able to load all the subviews progressively as it scroll. But all the previously loaded contetn will be stored and accumulated in the memory as well. The available memory for an app will be at the mercy of content provided. Using List with NSCache with defined limits will need to reload the content but will only use allocated memory.  And since there is limited number of items a List can present at a time before deallocations, we don't need to worry about thread explosions just yet. 
- Using function group vs swapable objects as dependencies: Usually when testing with mock objects, one could go with creating as many mock classes as the scenarios needed. But whenever there is a new functionality to be tested, one have to add functions to all the mock classes with a lot of margins for error, and time comsumptions. Declaring tuple of functions or struct of static functions as depdendencies can reduce the amount of code written and with great flexibility(say you only want part of the dependencies to be mocked). Yet this will face a challenge when dependencies require states, and mock object classes are more suitable.




## Weakest Part of the Project: 
I admit UI is not in the best of my strength.

## Additional Information:
Is there anything else we should know? Feel free to share any insights or constraints you encountered.

## Testing 

## Topics
### Classes
- ``APIManager``
- ``RecipeService``

### Protocols
- ``Logger``

### Enums
- ``APIError``
- ``HTTPMethod``


