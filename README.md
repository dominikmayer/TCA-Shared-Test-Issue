I have the following struct, which is shared in memory:

```Swift
struct Journal: Equatable {}

extension PersistenceReaderKey where Self == PersistenceKeyDefault<InMemoryKey<Journal?>> {
    static var journal: Self {
        return PersistenceKeyDefault(.inMemory("journal"), nil)
    }
}
```

I then have a feature that can show two other features, one of which contains the shared journal:

```Swift
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
```

And the feature that shows them:

```Swift
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
```

Now when trying to test this setup then the test passes when run on its own but fails when run together with another, independent test, that

a) shows the same destination as will be set in the brittle test and
b) sets the shared journal to `nil`.

This happens even when the test are run in `.serialized` mode.

```Swift
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
```
