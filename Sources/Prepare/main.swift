import Foundation

func downloadOpenAPI(toFolder folderUrl: URL) {
    let openapiRemoteUrl = URL(string: "https://raw.githubusercontent.com/tdlight-team/tdlight-telegram-bot-api/refs/heads/master/tdlight-api-openapi.yaml")!
    let content = try! String(contentsOf: openapiRemoteUrl)
    // Save yaml files to folderUrl
    try! content.write(to: folderUrl.appendingPathComponent("original.yaml"), atomically: true, encoding: .utf8)
    try! content.write(to: folderUrl.appendingPathComponent("openapi.yaml"), atomically: true, encoding: .utf8)
}

let currentFile = URL(fileURLWithPath: #filePath)
let projectRoot =
    currentFile
    .deletingLastPathComponent()  // Remove 'main.swift'
    .deletingLastPathComponent()  // Remove 'Prepare'
    .deletingLastPathComponent()  // Remove 'Sources'

downloadOpenAPI(toFolder: projectRoot.appendingPathComponent("Sources/TelegramBotAPI_AHC"))
// Generate code
try! runCommand("make generate-openapi", workingDirectory: projectRoot.path)
