//
//  Features.swift
//  Shared-Issue-2024
//
//  Created by Dominik Mayer on 25.10.24.
//

import ComposableArchitecture
import Foundation

extension PersistenceReaderKey where Self == PersistenceKeyDefault<InMemoryKey<Journal?>> {
    static var journal: Self {
        return PersistenceKeyDefault(.inMemory("journal"), nil)
    }
}

@Reducer
struct EntryFeature: Sendable {
    
    @ObservableState
    struct State: Equatable, Identifiable, Sendable {
        var id: URL {
            entry.id
        }
        
        var entry: Entry
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
                guard let journal = Shared(state.$journal),
                      let entry = Shared(journal[url])
                else {
                    return .none
                }

                let updatedEntryState = EntryFeature.State(entry: entry.wrappedValue)
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
