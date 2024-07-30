//
//  Outdated Package.swift
//  Cork
//
//  Created by David Bureš on 05.04.2023.
//

import Foundation
import CorkShared

struct OutdatedPackage: Identifiable, Equatable, Hashable
{
    let id: UUID = UUID()
    
    let package: BrewPackage
    
    let installedVersions: [String]
    let newerVersion: String
    
    var isMarkedForUpdating: Bool = true
}
