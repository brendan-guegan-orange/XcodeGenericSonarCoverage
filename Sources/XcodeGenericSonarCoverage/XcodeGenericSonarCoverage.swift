import Foundation
import SwiftShell

struct XcodeGenericSonarCoverage {
    let xcResultURL: URL
    
    init(derivedDataURL: URL) throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: derivedDataURL.path, isDirectory: &isDirectory) else {
            print("Indicated derived data path %@ does not exist", derivedDataURL.path)
            throw ExecutionError.derivedDataPathDoesNotExit
        }
        guard isDirectory.boolValue else {
            print("Indicated derived data path %@ is not a folder", derivedDataURL.path)
            throw ExecutionError.derivedDataPathIsNotADirectory
        }
        print("Looking for most recent xcresult folder")
        let resourceKeys : [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
        let directoryEnumerator = fileManager.enumerator(at: derivedDataURL,
                                                includingPropertiesForKeys: resourceKeys,
                                                options: [.skipsHiddenFiles])!
        var mostRecentXCResult: URL?
        var mostRecentCreationDate: Date?
        for case let fileURL as URL in directoryEnumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(resourceKeys)),
                let isDirectory = resourceValues.isDirectory,
                let creationDate = resourceValues.creationDate else {
                    continue
            }
            if "xcresult"  == fileURL.pathExtension,
                isDirectory {
                if nil == mostRecentCreationDate
                    || .orderedDescending == creationDate.compare(mostRecentCreationDate!) {
                    print("Found most recent xcresult at %@", fileURL.path)
                    mostRecentXCResult = fileURL
                    mostRecentCreationDate = creationDate
                }
                directoryEnumerator.skipDescendants()
            }
        }
        guard let xcResult = mostRecentXCResult else {
            throw ExecutionError.noXCResultFound
        }
        xcResultURL = xcResult
    }
    
    func generateCoverageReport(at destination: URL) throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: destination.path),
            !fileManager.createFile(atPath: destination.path, contents: nil, attributes: nil) {
            throw ExecutionError.unableToCreateReportFile
        }
        
        let fileHandle = try FileHandle(forWritingTo: destination)
        defer {
            fileHandle.closeFile()
        }
        fileHandle.write("<coverage version=\"1\">")
        
        let xccovExecution = SwiftShell.run(bash: "xcrun xccov view --json --report \(xcResultURL.path)")
        if !xccovExecution.succeeded {
            throw ExecutionError.xccovExecution(xccovExecution.error)
        }
        guard let outputData = xccovExecution.stdout.data(using: .utf8) else {
            throw ExecutionError.corruptedJsonReport
        }
        let decoder = JSONDecoder()
        let coverage = try decoder.decode(JSONCoverage.self, from: outputData)
        coverage.targets.forEach { target in
            target.files.forEach { file in
                fileHandle.write("\n\t<file path=\"\(file.path)\">")
                file.functions.forEach { function in
                    fileHandle.write("\n\t\t<lineToCover lineNumber=\"\(function.lineNumber)\"")
                    let covered = 0 == function.lineCoverage ? "false" : "true"
                    fileHandle.write("covered=\"\(covered)\"/>")
                }
                fileHandle.write("\n\t</file>")
            }
        }
        fileHandle.write("\n</coverage>")
    }
    
    enum ExecutionError: Error {
        case derivedDataPathDoesNotExit
        case derivedDataPathIsNotADirectory
        case noXCResultFound
        case unableToCreateReportFile
        case xccovExecution(SwiftShell.CommandError?)
        case corruptedJsonReport
    }
}

extension FileHandle {
    func write(_ string: String) {
        guard let data = string.data(using: .utf8) else {
            return
        }
        write(data)
    }
}

fileprivate struct JSONCoverage: Decodable {
    let coveredLines: Int
    let lineCoverage: Double
    let targets: [Target]
    
    struct Target: Decodable {
        let coveredLines: Int
        let lineCoverage: Double
        let files: [File]
        let name: String
        let executableLines: Int
        let buildProductPath: String
        
        struct File: Decodable {
            let coveredLines: Int
            let lineCoverage: Double
            let path: String
            let functions: [Function]
            let name: String
            let executableLines: Int
            
            struct Function: Decodable {
                let coveredLines: Int
                let lineCoverage: Int
                let lineNumber: Int
                let executionCount: Int
                let name: String
                let executableLines: Int
            }
        }
    }
}
