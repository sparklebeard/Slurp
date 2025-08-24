#!/usr/bin/env swift

import Foundation

// Define a custom error for mismatched list lengths
enum ListMatchError: Error {
    case mismatchedLengths(numbersCount: Int, namesCount: Int)
    case fileNotFound(path: String)
    case invalidFileFormat
    case readError(String)
    
    var localizedDescription: String {
        switch self {
        case .mismatchedLengths(let numbersCount, let namesCount):
            return "List lengths don't match: \(numbersCount) numbers vs \(namesCount) names"
        case .fileNotFound(let path):
            return "File not found at path: \(path)"
        case .invalidFileFormat:
            return "Invalid file format. Expected exactly 2 lines: numbers on first line, names on second line"
        case .readError(let message):
            return "Error reading file: \(message)"
        }
    }
}

// Function to match numbers and names from file
func matchFromFile(filePath: String) throws -> [(number: Int, name: String)] {
    // Sanitize the path
    let inputURL = URL(fileURLWithPath: filePath)
    let filePath = inputURL.path
    // Check if file exists
    guard FileManager.default.fileExists(atPath: filePath) else {
        throw ListMatchError.fileNotFound(path: filePath)
    }
    
    // Read file content
    let content: String
    do {
        content = try String(contentsOfFile: filePath, encoding: .utf8)
    } catch {
        throw ListMatchError.readError(error.localizedDescription)
    }
    
    // Split content into lines and filter out empty lines
    let lines = content.components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
    
    // Validate we have exactly 2 lines
    guard lines.count == 2 else {
        throw ListMatchError.invalidFileFormat
    }
    
    let numbersString = lines[0]
    let namesString = lines[1]
    
    // Parse numbers
    let numbers = numbersString
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .compactMap { Int($0) }
    
    // Parse names
    let names = namesString
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespaces) }
    
    // Check if lengths match
    guard numbers.count == names.count else {
        throw ListMatchError.mismatchedLengths(numbersCount: numbers.count, namesCount: names.count)
    }
    
    // Create matched pairs
    return zip(numbers, names).map { (number: $0, name: String($1)) }
}

// Function to print usage instructions
func printUsage() {
    print("Usage: swift matcher.swift <filepath>")
    print("")
    print("The file should contain exactly 2 lines:")
    print("Line 1: Comma-separated numbers")
    print("Line 2: Comma-separated names")
    print("")
    print("Example file content:")
    print("212971, 227659, 225591")
    print("Fleeting Tempered Potion, Fleeting Arcane Manifestation, Fleeting Massacre Footpads")
}

// Main execution
func main() {
    let arguments = CommandLine.arguments
    
    // Check if file path is provided
    guard arguments.count == 2 else {
        print("Error: Please provide a file path")
        print("")
        printUsage()
        exit(1)
    }
    
    let filePath = arguments[1]
    
    do {
        let matches = try matchFromFile(filePath: filePath)
        
        print("Successfully matched \(matches.count) items:")
        print("=" + String(repeating: "=", count: 80))
        
        for (index, match) in matches.enumerated() {
            print(String(format: "%3d. %-8d -> %@", index + 1, match.number, match.name))
        }
        
        print("=" + String(repeating: "=", count: 80))
        print("Total matches: \(matches.count)")
        
    } catch {
        print("Error: \(error.localizedDescription)")
        print("")
        printUsage()
        exit(1)
    }
}

// Run the main function
main()