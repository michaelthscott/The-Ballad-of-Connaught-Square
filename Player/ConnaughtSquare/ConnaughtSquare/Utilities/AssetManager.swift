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

func decodeAsset<Asset: Decodable>(_ name: String, from bundle: Bundle) -> Asset? {
    guard let asset = NSDataAsset(name: name, bundle: bundle) else { return nil }
    return try? PropertyListDecoder().decode(Asset.self, from: asset.data)
}

func decodeAssets<Asset: Decodable>(_ name: String, from bundle: Bundle) -> [Asset]? {
	guard let asset = NSDataAsset(name: name, bundle: bundle),
		  let assets = try? PropertyListDecoder().decode([Asset].self, from: asset.data) else {
		return nil
	}
	return assets
}

