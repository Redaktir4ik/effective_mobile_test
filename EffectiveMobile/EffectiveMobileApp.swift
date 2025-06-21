import ComposableArchitecture
import SwiftUI

@main
struct EffectiveMobileApp: App {
    var body: some Scene {
        WindowGroup {
            TasksListView(store: Store(
                initialState: TasksListFeature.State(),
                reducer: { TasksListFeature() }
            ))
        }
    }
}
