//
//  AssetManager.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 22/11/2023.
//

import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

enum AssetError: Error, CustomStringConvertible {
    /// The bundle has no data asset with the given name.
    case missing(name: String)

    var description: String {
        switch self {
        case .missing(let name):
            "No data asset named \"\(name)\""
        }
    }
}

/// The format of the data held in a data asset.
enum AssetFormat {
    case propertyList
    case json
}

/// Decodes a property list, or JSON, held in a data asset.
/// - Parameters:
///   - name: The name of the data asset.
///   - bundle: The bundle holding the asset.
///   - format: The format of the asset's data.
/// - Returns: The decoded value. To decode an array, give an array type.
/// - Throws: `AssetError.missing` if there's no such asset, or the `DecodingError` if it can't be decoded.
func decodeAsset<Asset: Decodable>(_ name: String, from bundle: Bundle, format: AssetFormat = .propertyList) throws -> Asset {
    guard let asset = NSDataAsset(name: name, bundle: bundle) else {
        throw AssetError.missing(name: name)
    }
    switch format {
    case .propertyList:
        return try PropertyListDecoder().decode(Asset.self, from: asset.data)
    case .json:
        return try JSONDecoder().decode(Asset.self, from: asset.data)
    }
}
