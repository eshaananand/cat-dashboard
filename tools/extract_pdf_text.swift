import Foundation
import PDFKit

let arguments = CommandLine.arguments.dropFirst()

guard arguments.count >= 2 else {
    fputs("Usage: extract_pdf_text.swift <output-dir> <pdf> [<pdf> ...]\n", stderr)
    exit(2)
}

let outputDirectory = URL(fileURLWithPath: String(arguments.first!))
try FileManager.default.createDirectory(
    at: outputDirectory,
    withIntermediateDirectories: true
)

for path in arguments.dropFirst() {
    let url = URL(fileURLWithPath: path)
    guard let document = PDFDocument(url: url) else {
        fputs("Could not open \(path)\n", stderr)
        continue
    }

    let text = document.string ?? ""
    let baseName = url.deletingPathExtension().lastPathComponent
    let outputURL = outputDirectory.appendingPathComponent("\(baseName).txt")
    try text.write(to: outputURL, atomically: true, encoding: .utf8)
    print("\(url.lastPathComponent): \(text.count) characters")
}
