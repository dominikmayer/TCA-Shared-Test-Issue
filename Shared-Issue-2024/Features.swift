//
//  Features.swift
//  Shared-Issue-2024
//
//  Created by Dominik Mayer on 25.10.24.
//

import ComposableArchitecture
import Foundation

// MARK: - Domain
struct Journal: Equatable {}

struct Entry: Equatable {
    var url: URL
}

// MARK: - Shared
extension PersistenceReaderKey where Self == PersistenceKeyDefault<InMemoryKey<Journal?>> {
    static var journal: Self {
        return PersistenceKeyDefault(.inMemory("journal"), nil)
    }
}

// MARK: - Destination Features
@Reducer
struct EntryFeature {
    
    @ObservableState
    struct State: Equatable {
        var url: URL
        @SharedReader(.journal) var journal
    }
}

@Reducer
struct DayFeature {
    
    @ObservableState
    struct State: Equatable {
        var entries: [EntryFeature.State]
    }
}

// MARK: - Parent Feature
@Reducer
struct CalendarFeature {
    
    @Reducer(state: .equatable)
    enum Destination {
        case day(DayFeature)
        case entry(EntryFeature)
    }
    
    @ObservableState
    struct State: Equatable {

        @Presents
        var destination: Destination.State?
        @Shared(.journal) var journal
    }
    
    enum Action: Equatable {
        case destination(PresentationAction<Destination.Action>)
        case loadEntry(URL)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
                
            case .loadEntry(let url):
                let updatedEntryState = EntryFeature.State(url: url)
                state.destination = .entry(updatedEntryState)
                return .none
                
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension CalendarFeature.Destination.Action: Equatable {}
