#!/bin/bash

# Set project name variable
PROJECT_NAME="$(basename "$(pwd)")"

# Initialize the package (assuming we're in the right directory with the same name as the project name above)
# swift package init --type library

# Add products
swift package add-product ${PROJECT_NAME}_AHC --type library --targets ${PROJECT_NAME}_AHC

# Add dependencies
swift package add-dependency https://github.com/apple/swift-openapi-generator --from 1.0.0
swift package add-dependency https://github.com/apple/swift-openapi-runtime --from 1.0.0
swift package add-dependency https://github.com/swift-server/swift-openapi-async-http-client --from 1.0.0

# Add targets
swift package add-target ${PROJECT_NAME}_AHC --type library
swift package add-target Prepare --type executable

# Add test targets
swift package add-target ${PROJECT_NAME}_AHCTests --type test --dependencies ${PROJECT_NAME}_AHC

# Add target dependencies for AHC
swift package add-target-dependency OpenAPIRuntime ${PROJECT_NAME}_AHC --package swift-openapi-runtime
swift package add-target-dependency OpenAPIAsyncHTTPClient ${PROJECT_NAME}_AHC --package swift-openapi-async-http-client

# Add platforms configuration after the first occurrence of the package name
sed -i '' '0,/name: "'"${PROJECT_NAME}"'",/{s/name: "'"${PROJECT_NAME}"'",/name: "'"${PROJECT_NAME}"'",\n    platforms: [.macOS(.v14), .iOS(.v17), .watchOS(.v6), .tvOS(.v13)],/}' Package.swift

# Create test directories
mkdir -p Tests/${PROJECT_NAME}_AHCTests/Resources
touch Tests/${PROJECT_NAME}_AHCTests/Resources/.gitkeep

# Create OpenAPI related files in project AHC
mkdir assets
# touch assets/openapi.yaml
# touch assets/original.yaml
touch assets/openapi-generator-config.yaml
cat <<EOL > assets/openapi-generator-config.yaml
generate:
  - types
  - client
accessModifier: public
EOL

# Create .env file
touch .env

# Completely replace the content of the .gitignore file
cat <<EOL > .gitignore
.DS_Store
/.build
/Packages
xcuserdata/
DerivedData/
.swiftpm
.netrc
.env
auth/

# Audio files
*.wav
*.mp3
*.m4a
*.aac
*.ogg
EOL

# # use sed to add the exclude and resources configurations
# # sed -i '' "s/name: \"${PROJECT_NAME}_AHC\",/name: \"${PROJECT_NAME}_AHC\",\n            exclude: [\n                \"openapi.yaml\",\n                \"original.yaml\",\n                \"openapi-generator-config.yaml\",\n            ],/" Package.swift
# sed -i '' "s/dependencies: \[\"${PROJECT_NAME}_AHC\"\],/dependencies: [\"${PROJECT_NAME}_AHC\"],\n            resources: [.copy(\"Resources\")],/" Package.swift

# Create some useful Swift files
# get env variables
touch Tests/${PROJECT_NAME}_AHCTests/getEnvVariables.swift
cat <<EOL > Tests/${PROJECT_NAME}_AHCTests/getEnvVariables.swift
import Foundation

func getEnvironmentVariable(_ name: String) -> String? {
    if let value = ProcessInfo.processInfo.environment[name] {
        return value
    }
    let currentFile = URL(fileURLWithPath: #filePath)
    let projectRoot =
        currentFile
        .deletingLastPathComponent()  // Remove 'main.swift'
        .deletingLastPathComponent()  // Remove 'Prepare'
        .deletingLastPathComponent()  // Remove 'Sources'
    let dotenv = projectRoot.appendingPathComponent(".env")
    let dotenvData = try! Data(contentsOf: dotenv)
    let dotenvString = String(data: dotenvData, encoding: .utf8)!
    let dotenvLines = dotenvString.split(separator: "\n")
    for line in dotenvLines {
        let parts = line.split(separator: "=")
        if parts[0] == name {
            return String(parts[1])
        }
    }
    return nil
}
EOL

# run terminal command file
touch Sources/Prepare/runCommand.swift
cat <<EOL > Sources/Prepare/runCommand.swift
import Foundation

func runCommand(_ command: String, workingDirectory: String? = nil) throws {
    let task = Process()
    let pipe = Pipe()

    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh")
    task.standardInput = nil

    if let workingDirectory {
        task.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
    }

    try task.run()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!

    print(#function, command, "\n", output)
}
EOL
