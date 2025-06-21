import Testing
import Foundation
import ComposableArchitecture

@testable import EffectiveMobile

@MainActor
final class TaskDetailsTest {
    // SECTION: type = .details
    // Проверка делатки задач
    @Test
    func testLoadDetails() async {
        let mock: TaskModel = .mock
        
        let client = TaskClientMock()
        let store = TestStore(
            initialState: TaskDetailsFeature.State(id: 1, type: .details)
        ) {
            TaskDetailsFeature()
        } withDependencies: {
            $0.taskClient = client
        }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear))
        
        await store.receive(\.data.loadTask.start) {
            $0.isLoading = true
        }
        
        await store.receive(\.data.loadTask.complete) {
            $0.isLoading = false
            $0.model = mock
            $0.date = DateTimeForward.stringToDate(mock.date)
        }
    }
    
    @Test
    func testErrorLoadDetails() async {
        let error = NSError(domain: "", code: 0, userInfo: nil)
        var client = TaskClientMock()
        client.testProxy?.loadTask = { _ in throw error }
        
        let store = TestStore(
            initialState: TaskDetailsFeature.State(id: 1, type: .details)
        ) {
            TaskDetailsFeature()
        } withDependencies: {
            $0.taskClient = client
        }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear))
        
        await store.receive(\.data.loadTask.start) {
            $0.isLoading = true
        }
        
        await store.receive(\.data.loadTask.fail) {
            $0.isLoading = false
        }
        
        #expect(store.state.toast != nil)
    }
    
    @Test
    func testEdditTapped() async {
        let mock: TaskModel = .mock
        
        let client = TaskClientMock()
        let store = TestStore(
            initialState: TaskDetailsFeature.State(id: 1, type: .details)
        ) {
            TaskDetailsFeature()
        } withDependencies: {
            $0.taskClient = client
        }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear))
        
        await store.receive(\.data.loadTask.start) {
            $0.isLoading = true
        }
        
        await store.receive(\.data.loadTask.complete) {
            $0.isLoading = false
            $0.model = mock
            $0.date = DateTimeForward.stringToDate(mock.date)
        }
        
        await store.send(.ui(.changeTapped)) {
            $0.type = .edit
        }
    }
    
    @Test
    func testChangeCompleted() async {
        let mock: TaskModel = .mock
        
        let client = TaskClientMock()
        let store = TestStore(
            initialState: TaskDetailsFeature.State(id: 1, type: .details)
        ) {
            TaskDetailsFeature()
        } withDependencies: {
            $0.taskClient = client
        }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear))
        
        await store.receive(\.data.loadTask.start) {
            $0.isLoading = true
        }
        
        await store.receive(\.data.loadTask.complete) {
            $0.isLoading = false
            $0.model = mock
            $0.date = DateTimeForward.stringToDate(mock.date)
        }
        
        await store.send(.ui(.completedTapped)) {
            $0.model.completed = true
        }
        
        await store.receive(\.data.updateCompletionStatus.start)
        await store.receive(\.data.updateCompletionStatus.complete)
    }
    
    @Test
    func testChangeCompletedError() async {
        let mock: TaskModel = .mock
        
        let error = NSError(domain: "", code: 0, userInfo: nil)
        var client = TaskClientMock()
        client.testProxy?.updateTaskCompletionStatus = { _, _ in throw error }
        
        let store = TestStore(
            initialState: TaskDetailsFeature.State(id: 1, type: .details)
        ) {
            TaskDetailsFeature()
        } withDependencies: {
            $0.taskClient = client
        }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear))
        
        await store.receive(\.data.loadTask.start) {
            $0.isLoading = true
        }
        
        await store.receive(\.data.loadTask.complete) {
            $0.isLoading = false
            $0.model = mock
            $0.date = DateTimeForward.stringToDate(mock.date)
        }
        
        await store.send(.ui(.completedTapped)) {
            $0.model.completed = true
        }
        
        await store.receive(\.data.updateCompletionStatus.start)
        await store.receive(\.data.updateCompletionStatus.fail)
        #expect(store.state.toast != nil)
    }
    
    // SECTION: type = .edit
    // Проверка изменения задач
    @Test
    func testSaveEditDetails() async {
        let mock: TaskModel = .mock
        
        let client = TaskClientMock()
        let store = TestStore(
            initialState: TaskDetailsFeature.State(id: 1, type: .edit)
        ) {
            TaskDetailsFeature()
        } withDependencies: {
            $0.taskClient = client
        }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear))
        
        await store.receive(\.data.loadTask.start) {
            $0.isLoading = true
        }
        
        await store.receive(\.data.loadTask.complete) {
            $0.isLoading = false
            $0.model = mock
            $0.date = DateTimeForward.stringToDate(mock.date)
        }
        
        await store.send(.ui(.saveTapped))
        
        await store.receive(\.data.saveTask.start)
        await store.receive(\.data.saveTask.complete)
    }
    
    @Test
    func testErrorSaveEditDetails() async {
        let mock: TaskModel = .mock
        
        let error = NSError(domain: "", code: 0, userInfo: nil)
        var client = TaskClientMock()
        client.testProxy?.updateTask = { _ in throw error }
        
        let store = TestStore(
            initialState: TaskDetailsFeature.State(id: 1, type: .edit)
        ) {
            TaskDetailsFeature()
        } withDependencies: {
            $0.taskClient = client
        }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear))
        
        await store.receive(\.data.loadTask.start) {
            $0.isLoading = true
        }
        
        await store.receive(\.data.loadTask.complete) {
            $0.isLoading = false
            $0.model = mock
            $0.date = DateTimeForward.stringToDate(mock.date)
        }
        
        await store.send(.ui(.saveTapped))
        
        await store.receive(\.data.saveTask.start)
        await store.receive(\.data.saveTask.fail)
        #expect(store.state.toast != nil)
    }
    
    // SECTION: type = .edit
    // Проверка создания задачи
    
    @Test
    func testSaveCreateDetails() async {
        let mock: TaskModel = .mock
        
        let client = TaskClientMock()
        let store = TestStore(
            initialState: TaskDetailsFeature.State(id: 1, type: .edit)
        ) {
            TaskDetailsFeature()
        } withDependencies: {
            $0.taskClient = client
        }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear))
        
        await store.receive(\.data.getUserIds.start)
        
        await store.receive(\.data.getUserIds.complete) {
            $0.userIds = []
        }
        
        await store.send(.binding(.set(\.model, mock)))
        
        await store.send(.ui(.saveTapped))
        await store.receive(\.data.saveTask.start)
        await store.receive(\.data.saveTask.complete)
    }
}
