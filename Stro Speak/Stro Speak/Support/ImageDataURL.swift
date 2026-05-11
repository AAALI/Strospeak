import AppKit
import SwiftUI

func imageFromDataURL(_ dataURL: String) -> NSImage? {
    guard let commaIndex = dataURL.lastIndex(of: ",") else { return nil }
    let base64 = String(dataURL[dataURL.index(after: commaIndex)...])
    guard let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) else { return nil }
    return NSImage(data: data)
}
