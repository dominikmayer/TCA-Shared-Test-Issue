//
//  Shared_Issue_2024Tests.swift
//  Shared-Issue-2024Tests
//
//  Created by Dominik Mayer on 25.10.24.
//

import ComposableArchitecture
import Foundation
import Testing

@Suite(.serialized)
@MainActor
struct Test_CalendarFeature {

    let journal = Journal()
        
    @Test
    func settingSharedVariableNil() async {
        // We never use this store but if we remove it, the issue doesn't appear
        let _ = TestStore(
            initialState: .init(
                // This has to be the same entry that will be set by the other test. You can try to change it to .entryFeature2 and everything passes
                destination: .day(.init(entries: [.entryFeature1]))
            )
        ) {
            CalendarFeature()
        }

        @Shared(.journal) var sharedJournal
        $sharedJournal.withLock {
            $0 = nil
        }
        // We can but don't even need to send an action here
    }
    
    // This test passes when it's run alone but fails when it's run as part of the suite together with the other test, even when both tests are serialized
    @Test
    func brittleTest() async {
        @Shared(.journal) var sharedJournal
        $sharedJournal.withLock {
            $0 = journal
        }

        let store = TestStore(
            initialState: .init()
        ) {
            CalendarFeature()
        }
        
        await store.send(.loadEntry(.entry1)) {
            $0.destination = .entry(.entryFeature1)
        }
    }
}

// MARK: - Test Items
extension URL {
    static let entry1 = URL(fileURLWithPath: "/some/path/")
    static let entry2 = URL(fileURLWithPath: "/some/other/path/")
}

extension Entry {
    static let entry1 = Entry(
        url: .entry1
    )
    static let entry2 = Entry(
        url: .entry2
    )
}

extension EntryFeature.State {
    static let entryFeature1 = EntryFeature.State(
        url: .entry1
    )
    static let entryFeature2 = EntryFeature.State(
        url: .entry2
    )
}
