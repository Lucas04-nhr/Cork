//
//  Export Brewfile.swift
//  Cork
//
//  Created by David Bureš on 10.11.2023.
//

import Foundation

extension HomebrewBackup
{
    func exportHomebrewBackup() async throws -> Void
    {
        let brewfileUUID: UUID = .init()
        
        let brewfileParentLocation: URL = URL.temporaryDirectory
        
        AppConstants.logger.debug("Will use \(brewfileParentLocation) as temp parent directory for Homebrew backup")
        
        let brewfileDumpingResult: TerminalOutput = await shell(AppConstants.brewExecutablePath, ["bundle", "dump", "--file=\"\(brewfileParentLocation.appending(path: brewfileUUID.uuidString))\"", "--verbose", "--debug"], workingDirectory: URL.userDirectory)
        
        AppConstants.logger.debug("Output of brewfile dumping: \(brewfileDumpingResult.standardOutput), \(brewfileDumpingResult.standardError)")
    }
}

enum BrewfileDumpingError: Error
{
    case couldNotDetermineWorkingDirectory, errorWhileDumpingBrewfile(error: String), couldNotReadBrewfile
}

/// Exports the Brewfile and returns the contents of the Brewfile itself for further manipulation. Does not preserve the Brewfile
@MainActor
func exportBrewfile(appState: AppState) async throws -> String
{
    appState.isShowingBrewfileExportProgress = true
    
    defer
    {
        appState.isShowingBrewfileExportProgress = false
    }
    
    let brewfileParentLocation = URL.temporaryDirectory
    
    let pathRawOutput = await shell(URL(string: "/bin/pwd")!, ["-L"])
    
    let brewfileDumpingResult: TerminalOutput = await shell(AppConstants.brewExecutablePath, ["bundle", "-f", "dump"], workingDirectory: brewfileParentLocation)
    
    /// Throw an error if the working directory could not be determined
    if !pathRawOutput.standardError.isEmpty
    {
        throw BrewfileDumpingError.couldNotDetermineWorkingDirectory
    }

    /// Throw an error if the working directory is so fucked up it's unusable
    guard let workingDirectory = URL(string: pathRawOutput.standardOutput.replacingOccurrences(of: "\n", with: ""))
    else
    {
        throw BrewfileDumpingError.couldNotDetermineWorkingDirectory
    }
    
    if !brewfileDumpingResult.standardError.isEmpty
    {
        throw BrewfileDumpingError.errorWhileDumpingBrewfile(error: brewfileDumpingResult.standardError)
    }
    
    AppConstants.logger.info("Path: \(workingDirectory, privacy: .auto)")
    
    print("Brewfile dumping result: \(brewfileDumpingResult)")
    
    let brewfileLocation: URL = brewfileParentLocation.appendingPathComponent("Brewfile", conformingTo: .fileURL)
    
    do
    {
        let brewfileContents: String = try String(contentsOf: brewfileLocation)
        
        /// Delete the brewfile
        try? FileManager.default.removeItem(at: brewfileLocation)
        
        return brewfileContents
    }
    catch let brewfileReadingError
    {
        AppConstants.logger.error("Error while reading contents of Brewfile: \(brewfileReadingError, privacy: .public)")
        throw BrewfileDumpingError.couldNotReadBrewfile
    }
}
