//
//  Weighted.swift
//  ConnaughtSquare
//
//  Created by Michael Scott on 11/12/2023.
//

/// A value that carries a weight, such as how often it occurs.
///
/// The weight isn't part of the value's identity: conforming types' `==`, `<` and `hash(into:)`
/// must all ignore it, so that a `WeightedSet` can find an element whatever its weight.
/// Order by weight explicitly where it's needed.
protocol Weighted {
    var weight: Int { get set }
}
