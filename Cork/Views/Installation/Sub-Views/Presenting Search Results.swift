//
//  Presenting Search Results.swift
//  Cork
//
//  Created by David Bureš on 29.09.2023.
//

import SwiftUI

struct PresentingSearchResultsView: View
{
    @Environment(\.dismiss) var dismiss: DismissAction
    @Environment(\.openWindow) var openWindow: OpenWindowAction

    @EnvironmentObject var appState: AppState

    @ObservedObject var searchResultTracker: SearchResultTracker

    @Binding var packageRequested: String
    @Binding var foundPackageSelection: UUID?

    @Binding var packageInstallationProcessStep: PackageInstallationProcessSteps

    @ObservedObject var installationProgressTracker: InstallationProgressTracker

    @State private var isFormulaeSectionCollapsed: Bool = false
    @State private var isCasksSectionCollapsed: Bool = false

    @State var isSearchFieldFocused: Bool = true

    var body: some View
    {
        VStack
        {
            InstallProcessCustomSearchField(search: $packageRequested, isFocused: $isSearchFieldFocused, customPromptText: String(localized: "add-package.search.prompt"))
            {
                foundPackageSelection = nil // Clear all selected items when the user looks for a different package
            }

            List(selection: $foundPackageSelection)
            {
                SearchResultsSection(
                    sectionType: .formula,
                    packageList: searchResultTracker.foundFormulae
                )

                SearchResultsSection(
                    sectionType: .cask,
                    packageList: searchResultTracker.foundCasks
                )
            }
            .listStyle(.bordered(alternatesRowBackgrounds: true))
            .frame(width: 300, height: 300)

            HStack
            {
                DismissSheetButton()

                Spacer()

                // Show the preview window on macOS 14 and newer only
                if #available(macOS 14, *)
                {
                    Button
                    {
                        do
                        {
                            let requestedPackageToPreview: BrewPackage = try foundPackageSelection!.getPackage(tracker: searchResultTracker)
                            
                            openWindow(value: requestedPackageToPreview)
                            
                            AppConstants.logger.debug("Would preview package \(requestedPackageToPreview.name)")
                        } catch let error
                        {
                            
                        }
                    } label: {
                        Text("preview-package.action")
                    }
                    .disabled(foundPackageSelection == nil)
                }
                
                if isSearchFieldFocused
                {
                    Button
                    {
                        packageInstallationProcessStep = .searching
                    } label: {
                        Text("add-package.search.action")
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(packageRequested.isEmpty)
                }
                else
                {
                    Button
                    {
                        getRequestedPackages()

                        packageInstallationProcessStep = .installing
                    } label: {
                        Text("add-package.install.action")
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(foundPackageSelection == nil)
                }
            }
        }
    }

    private func getRequestedPackages()
    {
        if let foundPackageSelection
        {
            do
            {
                let packageToInstall: BrewPackage = try foundPackageSelection.getPackage(tracker: searchResultTracker)

                installationProgressTracker.packageBeingInstalled = PackageInProgressOfBeingInstalled(package: packageToInstall, installationStage: .ready, packageInstallationProgress: 0)

                #if DEBUG
                    AppConstants.logger.info("Packages to install: \(installationProgressTracker.packageBeingInstalled.package.name, privacy: .public)")
                #endif
            }
            catch let packageByUUIDRetrievalError
            {
                #if DEBUG
                    AppConstants.logger.error("Failed while associating package with its ID: \(packageByUUIDRetrievalError, privacy: .public)")
                #endif

                dismiss()

                appState.showAlert(errorToShow: .couldNotAssociateAnyPackageWithProvidedPackageUUID)
            }
        }
    }
}

private struct SearchResultsSection: View
{
    fileprivate enum SectionType
    {
        case formula, cask
    }

    let sectionType: SectionType

    let packageList: [BrewPackage]

    @State private var isSectionCollapsed: Bool = false

    var body: some View
    {
        Section
        {
            if !isSectionCollapsed
            {
                ForEach(packageList)
                { package in
                    SearchResultRow(searchedForPackage: package)
                }
            }
        } header: {
            CollapsibleSectionHeader(headerText: sectionType == .formula ? "add-package.search.results.formulae" : "add-package.search.results.casks", isCollapsed: $isSectionCollapsed)
        }
    }
}
