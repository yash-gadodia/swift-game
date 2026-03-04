require 'rubygems'
require 'xcodeproj'

project_path = 'SwiftGame.xcodeproj'
project = Xcodeproj::Project.new(project_path)

project.build_configuration_list.build_configurations.each do |config|
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1'
end

main_group = project.main_group
app_group = main_group.new_group('SwiftGame', 'SwiftGame')
app_subgroups = {
  'App' => app_group.new_group('App', 'App'),
  'Scenes' => app_group.new_group('Scenes', 'Scenes'),
  'Networking' => app_group.new_group('Networking', 'Networking'),
  'Game' => app_group.new_group('Game', 'Game'),
  'UI' => app_group.new_group('UI', 'UI')
}

tests_group = main_group.new_group('SwiftGameTests', 'SwiftGameTests')

app_target = project.new_target(:application, 'SwiftGame', :ios, '16.0')
tests_target = project.new_target(:unit_test_bundle, 'SwiftGameTests', :ios, '16.0')
tests_target.add_dependency(app_target)

frameworks_group = project.frameworks_group
['SpriteKit.framework'].each do |framework|
  ref = frameworks_group.new_file("System/Library/Frameworks/#{framework}")
  app_target.frameworks_build_phase.add_file_reference(ref, true)
end

sources = {
  'App' => ['AppDelegate.swift', 'SceneDelegate.swift'],
  'Scenes' => ['GameScene.swift'],
  'Networking' => ['NetMessages.swift', 'MultipeerSessionManager.swift', 'APIModels.swift', 'APIClient.swift'],
  'Game' => ['GameState.swift'],
  'UI' => ['LobbyViewController.swift', 'GameViewController.swift', 'VirtualDPad.swift']
}

sources.each do |folder, files|
  files.each do |file|
    ref = app_subgroups[folder].new_file(file)
    app_target.add_file_references([ref])
  end
end

assets_ref = app_group.new_file('Assets.xcassets')
app_target.resources_build_phase.add_file_reference(assets_ref, true)

tests = ['NetMessagesTests.swift', 'GameStateTests.swift']
tests.each do |file|
  ref = tests_group.new_file(file)
  tests_target.add_file_references([ref])
end

[app_target, tests_target].each do |target|
  target.build_configurations.each do |config|
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    config.build_settings['TARGETED_DEVICE_FAMILY'] = '1'
  end
end

app_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.voltade.swiftgame'
  config.build_settings['INFOPLIST_FILE'] = 'SwiftGame/App/Info.plist'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['DEVELOPMENT_TEAM'] = ''
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks']
end

tests_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.voltade.swiftgameTests'
  config.build_settings['TEST_TARGET_NAME'] = 'SwiftGame'
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/SwiftGame.app/SwiftGame'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['DEVELOPMENT_TEAM'] = ''
end

project.save

scheme_dir = File.join(project_path, 'xcshareddata', 'xcschemes')
Dir.mkdir(File.join(project_path, 'xcshareddata')) unless Dir.exist?(File.join(project_path, 'xcshareddata'))
Dir.mkdir(scheme_dir) unless Dir.exist?(scheme_dir)

scheme_xml = <<~XML
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.3">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "#{app_target.uuid}"
               BuildableName = "SwiftGame.app"
               BlueprintName = "SwiftGame"
               ReferencedContainer = "container:SwiftGame.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "NO"
            buildForProfiling = "NO"
            buildForArchiving = "NO"
            buildForAnalyzing = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "#{tests_target.uuid}"
               BuildableName = "SwiftGameTests.xctest"
               BlueprintName = "SwiftGameTests"
               ReferencedContainer = "container:SwiftGame.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <MacroExpansion>
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "#{app_target.uuid}"
            BuildableName = "SwiftGame.app"
            BlueprintName = "SwiftGame"
            ReferencedContainer = "container:SwiftGame.xcodeproj">
         </BuildableReference>
      </MacroExpansion>
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "#{tests_target.uuid}"
               BuildableName = "SwiftGameTests.xctest"
               BlueprintName = "SwiftGameTests"
               ReferencedContainer = "container:SwiftGame.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "#{app_target.uuid}"
            BuildableName = "SwiftGame.app"
            BlueprintName = "SwiftGame"
            ReferencedContainer = "container:SwiftGame.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "#{app_target.uuid}"
            BuildableName = "SwiftGame.app"
            BlueprintName = "SwiftGame"
            ReferencedContainer = "container:SwiftGame.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
XML

File.write(File.join(scheme_dir, 'SwiftGame.xcscheme'), scheme_xml)
