//
//  Domain.swift
//  Shared-Issue-2024
//
//  Created by Dominik Mayer on 25.10.24.
//

import ComposableArchitecture
import Foundation

struct Journal: Equatable, Sendable {
    
    var entries: IdentifiedArrayOf<Entry>
        
    subscript(entryId: URL) -> Entry? {
        get {
            return entries.first(where: { $0.id == entryId })
        }
        set(newValue) {
            entries[id: entryId] = newValue
        }
    }
}

struct Entry: Sendable, Equatable, Identifiable {
    var url: URL
    var id: URL {
        url
    }
}
