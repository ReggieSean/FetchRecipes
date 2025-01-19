//
//  File.swift
//  RecipeLibrary
//
//  Created by SeanHuang on 12/29/24.
//



import Foundation
///Async Logging extension for unified printing
//Usage: Extend the protocol to a class, actor or struct, and print with printF or Self.printF whether it's in async context,or sync context in instance or static functions.
@available(iOS 16.0, *)
public protocol AsyncDebugLogger{
    ///Print a formatted output string,
    /// - Parameter str: Main text without formatting
    func printF(_ str : String,_ file: String ,_ function: String,_ line: Int)
    
    //static function requires static dispatch so classes need implementation
    //you could just provide the static function in extension for static dispatch
    // like below:

}

public extension AsyncDebugLogger{
    
    /// Call this fucntion with CallingClass.printF(), not capturing an instance, might not show when mainthread is being crowded by urgent task
    /// - Parameters:
    ///   - str: message
    ///   - file: leave blank for caller to fill
    ///   - function: leave blank for caller to fill
    ///   - line: leave blank for caller to fill
    static func printF(_ str : String,_ file: String = #file,_ function: String = #function,_ line: Int = #line){
        #if DEBUG
        //print("\(#file)-(\(#function))-(\(#line)):")
        Task{@MainActor in
            print("\(file)-(\(function))-(\(line)):")
            print("static-->"+str)
            print("\n")
            fflush(stdout)
        }
        #endif
    }
    /// Call this fucntion with printF() equivalent with self.printF, implicitly capturing self
    /// - Parameters:
    ///   - str: message
    ///   - file: leave blank for caller to fill
    ///   - function: leave blank for caller to fill
    ///   - line: leave blank for caller to fill
    func printF(_ str : String,_ file: String = #file,_ function: String = #function,_ line: Int = #line){
        #if DEBUG
//        print("\(#file)-(\(#function))-(\(#line)):")
        Task{ @MainActor in
            print("\(file)-(\(function))-(\(line)):")
            print("self-->" + str)
            print("\n")
            fflush(stdout)
        }
        #endif
    }
}

///Debug Logging extension for unified printing
@available(iOS 16.0, *)
public protocol DebugLogger{
    ///Print a formatted output string,
    /// - Parameter str: Main text without formatting
    func printF(_ str : String,_ file: String ,_ function: String,_ line: Int)
    
    //static function requires static dispatch so classes need implementation
    //you could just provide the static function in extension for static dispatch
    // like below:

}

public extension DebugLogger{
    
    /// Call this fucntion with CallingClass.printF(), not capturing an instance
    /// - Parameters:
    ///   - str: message
    ///   - file: leave blank for caller to fill
    ///   - function: leave blank for caller to fill
    ///   - line: leave blank for caller to fill
    static func printF(_ str : String,_ file: String = #file,_ function: String = #function,_ line: Int = #line){
        #if DEBUG
        //print("\(#file)-(\(#function))-(\(#line)):")
        print("\(file)-(\(function))-(\(line)):")
        print("static-->"+str)
        print("\n")
        fflush(stdout)
        #endif
    }
    /// Call this fucntion with printF() equivalent with self.printF, implicitly capturing self
    /// - Parameters:
    ///   - str: message
    ///   - file: leave blank for caller to fill
    ///   - function: leave blank for caller to fill
    ///   - line: leave blank for caller to fill
    func printF(_ str : String,_ file: String = #file,_ function: String = #function,_ line: Int = #line){
        #if DEBUG
//        print("\(#file)-(\(#function))-(\(#line)):")
        print("\(file)-(\(function))-(\(line)):")
        print("self-->" + str)
        print("\n")
        fflush(stdout)
        #endif
    }
}

///Logging extension for unified printing
public protocol Logger{
    ///Print a formatted output string
    /// - Parameter str: Main text without formatting
    func printF(_ str : String)
}
public extension Logger{
    static func printF(_ str : String){
        print(str)
        print("\n")
        fflush(stdout)
    }
    func printF(_ str : String){
        print(str)
        print("\n")
        fflush(stdout)
    }
}

protocol InfoPrinter{
    
}
extension InfoPrinter{
    static func printModuleResources(){
        guard let resourceURL = Bundle.module.resourceURL else {
                    print("No resource URL found for module.")
                    return
                }

                
            do {
                let resourceContents = try FileManager.default.contentsOfDirectory(at: resourceURL, includingPropertiesForKeys: nil, options: [])
                print("Resources in module:")
                for file in resourceContents {
                    print(file.lastPathComponent)
                }
                
            } catch {
                print("Failed to list resources: \(error)")
                
            }
    }
}
