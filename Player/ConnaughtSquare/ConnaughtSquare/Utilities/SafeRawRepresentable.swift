//
//  SafeRawRepresentable.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 14/12/2023.
//

protocol SafeRawRepresentable: RawRepresentable {
    init(rawValue: Self.RawValue)
}
