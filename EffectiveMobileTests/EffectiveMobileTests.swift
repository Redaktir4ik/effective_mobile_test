import Testing
import Foundation
import ComposableArchitecture

@testable import EffectiveMobile

@MainActor
final class TaskListTest {
    // SECTION: Загрузка данных с json
    @Test
    func testLoadByApi() async {
        // Проверка загрузки данных с json файла
        // 1. Открытие приложение в первый раз
        // 2. Начало загрузки с json файла
        // 3. Проверка данных при окончании загрузки
        // 4. Проверка сохранения данных в core data
        let mockData: [TaskModel] = [.mock]
        
        let client = TaskClientMock()
        let store = TestStore(
            initialState: TasksListFeature.State()
        ) {
            TasksListFeature()
        } withDependencies: {
            $0.taskClient = client
        }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear(true)))
        
        await store.receive(\.data.loadTasksUrl.start) {
            $0.isLoading = true
        }
        
        await store.receive(\.data.loadTasksUrl.complete) {
            $0.isLoading = false
            $0.tasks = mockData
        }
        
        await store.receive(\.data.saveTasksCoreData.start)
        await store.receive(\.data.saveTasksCoreData.complete)
        #expect(store.state.toast != nil)
    }
    
    @Test
    func testErrorLoadUrl() async {
        // Проверка обработки ошибки при загрузки данных с json
        
        let error = NSError(domain: "", code: 0, userInfo: nil)
        var client = TaskClientMock()
        client.testProxy?.loadTasksUrl = { throw error }
        
        let store = TestStore(
            initialState: TasksListFeature.State()
          ) {
              TasksListFeature()
          } withDependencies: {
              $0.taskClient = client
          }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear(true)))
        
        await store.receive(\.data.loadTasksUrl.start) {
            $0.isLoading = true
        }
        
        await store.receive(\.data.loadTasksUrl.fail)
        #expect(store.state.toast != nil)
    }
    
    @Test
    func testErrorSaveCoreData() async {
        // Проверка обработки ошибки при сохранении данных в Core Data после загрузки данных с json
        let mockData: [TaskModel] = [.mock]
        let error = NSError(domain: "", code: 0, userInfo: nil)
        
        var client = TaskClientMock()
        client.testProxy?.saveTasks = { _ in throw error }
        
        let store = TestStore(
            initialState: TasksListFeature.State()
          ) {
              TasksListFeature()
          } withDependencies: {
              $0.taskClient = client
          }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear(true)))
        
        await store.receive(\.data.loadTasksUrl.start) {
            $0.isLoading = true
        }
        
        await store.receive(\.data.loadTasksUrl.complete) {
            $0.isLoading = false
            $0.tasks = mockData
        }
        
        await store.receive(\.data.saveTasksCoreData.start)
        await store.receive(\.data.saveTasksCoreData.fail)
        
        #expect(store.state.toast != nil)
    }
    
    // SECTION: Загрузка данных с Core Data
    @Test
    func testLoadByCoreData() async {
        // Проверка загрузки данных с Core Data
        let mockData: [TaskModel] = [.mock]
        
        let client = TaskClientMock()
        let store = TestStore(
            initialState: TasksListFeature.State()
        ) {
            TasksListFeature()
        } withDependencies: {
            $0.taskClient = client
        }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear(false)))
        
        await store.receive(\.data.loadTasksCoreData.start) {
            $0.isLoading = true
        }
        
        await store.receive(\.data.loadTasksCoreData.complete) {
            $0.isLoading = false
            $0.tasks = mockData
        }
    }
    
    @Test
    func testErrorLoadCoreData() async {
        // Проверка обработки ошибки при загрузки данных с Core Data
        
        let error = NSError(domain: "", code: 0, userInfo: nil)
        var client = TaskClientMock()
        client.testProxy?.loadTasksCoreData = { throw error }
        
        let store = TestStore(
            initialState: TasksListFeature.State()
          ) {
              TasksListFeature()
          } withDependencies: {
              $0.taskClient = client
          }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear(false)))
        
        await store.receive(\.data.loadTasksCoreData.start) {
            $0.isLoading = true
        }
        
        await store.receive(\.data.loadTasksCoreData.fail) {
            $0.isLoading = false
        }
        #expect(store.state.toast != nil)
    }
    
    // SECTION: Проверка поиска и фильтрации
    @Test
    func testSearchTask() async {
        // Проверка загрузки данных с Core Data
        let mockData: [TaskModel] = [.mock]
        
        let client = TaskClientMock()
        let store = TestStore(
            initialState: TasksListFeature.State()
        ) {
            TasksListFeature()
        } withDependencies: {
            $0.taskClient = client
        }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear(false)))
        
        await store.receive(\.data.loadTasksCoreData.start) {
            $0.isLoading = true
        }
        
        await store.receive(\.data.loadTasksCoreData.complete) {
            $0.isLoading = false
            $0.tasks = mockData
        }
        
        await store.send(.binding(.set(\.filterTask.text, "")))
        
        await store.receive(\.data.searchTask.start)
        await store.receive(\.data.searchTask.complete) {
            $0.tasks = mockData
        }
        
        await store.send(.ui(.filtersTapped)) {
            $0.openFilters.toggle()
        }
        
        await store.send(.ui(.filterTaskTypeSelect(.uncompleted))) {
            $0.filterTask.taskType = .uncompleted
        }
        
        await store.receive(\.data.searchTask.start)
        await store.receive(\.data.searchTask.complete) {
            $0.tasks = mockData
        }
        
        await store.send(.binding(.set(\.filterTask.date, Date.now)))
        
        await store.receive(\.data.searchTask.start)
        await store.receive(\.data.searchTask.complete) {
            $0.tasks = mockData
        }
        
        await store.send(.ui(.userIsdSelected(mockData[0].userId))) {
            $0.filterTask.taskType = .uncompleted
        }
        
        await store.receive(\.data.searchTask.start)
        await store.receive(\.data.searchTask.complete) {
            $0.tasks = mockData
        }
    }
    
    @Test
    func testErrorSearchTask() async {
        // Проверка ошибки при поиске данных в Core Data
        let mockData: [TaskModel] = [.mock]
        let error = NSError(domain: "", code: 0, userInfo: nil)
        
        var client = TaskClientMock()
        client.testProxy?.searchTask = { _, _, _, _ in throw error }
        
        let store = TestStore(
            initialState: TasksListFeature.State()
        ) {
            TasksListFeature()
        } withDependencies: {
            $0.taskClient = client
        }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear(false)))
        
        await store.receive(\.data.loadTasksCoreData.start) {
            $0.isLoading = true
        }
        
        await store.receive(\.data.loadTasksCoreData.complete) {
            $0.isLoading = false
            $0.tasks = mockData
        }
        
        await store.send(.binding(.set(\.filterTask.text, "")))
        await store.receive(\.data.searchTask.start)
        await store.receive(\.data.searchTask.fail)
        
        #expect(store.state.toast != nil)
    }
    
    // SECTION: Проверка открытия детальной информации(просмотр, изменение, добавление)
    @Test
    func testOpenTaskDetails() async {
        // Проверка открытия детальной информации о задачи
        let mockData: [TaskModel] = [.mock]
        let mock: TaskModel = .mock
        
        let client = TaskClientMock()
        let store = TestStore(
            initialState: TasksListFeature.State()
        ) {
            TasksListFeature()
        } withDependencies: {
            $0.taskClient = client
        }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear(false)))
        
        await store.receive(\.data.loadTasksCoreData.start) {
            $0.isLoading = true
        }
        
        await store.receive(\.data.loadTasksCoreData.complete) {
            $0.isLoading = false
            $0.tasks = mockData
        }
        
        await store.send(.ui(.taskTapped(mock))) {
            $0.destination = .details(
                TaskDetailsFeature.State(id: mock.id, type: .details)
            )
        }
    }
    
    @Test
    func testEditTaskDetails() async {
        // Проверка открытия детальной информации о задачи
        let mockData: [TaskModel] = [.mock]
        let mock: TaskModel = .mock
        
        let client = TaskClientMock()
        let store = TestStore(
            initialState: TasksListFeature.State()
        ) {
            TasksListFeature()
        } withDependencies: {
            $0.taskClient = client
        }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear(false)))
        
        await store.receive(\.data.loadTasksCoreData.start) {
            $0.isLoading = true
        }
        
        await store.receive(\.data.loadTasksCoreData.complete) {
            $0.isLoading = false
            $0.tasks = mockData
        }
        
        await store.send(.ui(.editTask(mock))) {
            $0.destination = .details(
                TaskDetailsFeature.State(id: mock.id, type: .edit)
            )
        }
    }
    
    @Test
    func testCreateTaskDetails() async {
        // Проверка открытия детальной информации о задачи
        let mockData: [TaskModel] = [.mock]
        
        let client = TaskClientMock()
        let store = TestStore(
            initialState: TasksListFeature.State()
        ) {
            TasksListFeature()
        } withDependencies: {
            $0.taskClient = client
        }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear(false)))
        
        await store.receive(\.data.loadTasksCoreData.start) {
            $0.isLoading = true
        }
        
        await store.receive(\.data.loadTasksCoreData.complete) {
            $0.isLoading = false
            $0.tasks = mockData
        }
        
        await store.send(.ui(.createTask)) {
            $0.destination = .details(
                TaskDetailsFeature.State(id: nil, type: .create)
            )
        }
    }
    
    // SECTION: Проверка остального функционала
    @Test
    func testShareTask() async {
        // Проверка нажатия на кнопку поделиться
        let mockData: [TaskModel] = [.mock]
        
        let client = TaskClientMock()
        let store = TestStore(
            initialState: TasksListFeature.State()
        ) {
            TasksListFeature()
        } withDependencies: {
            $0.taskClient = client
        }
        
        store.exhaustivity = .off
        
        await store.send(.ui(.onAppear(false)))
        
        await store.receive(\.data.loadTasksCoreData.start) {
            $0.isLoading = false
        }
        
        await store.receive(\.data.loadTasksUrl.complete) {
            $0.isLoading = false
            $0.tasks = mockData
        }
        
        await store.send(.ui(.shareTask(.mock)))
    }
}
