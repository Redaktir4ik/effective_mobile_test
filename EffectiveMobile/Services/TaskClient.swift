import Dependencies
import Foundation

private struct TaskLoadData: Sendable, Equatable, Decodable {
    struct Base: Sendable, Equatable, Decodable {
        var id: Int
        var todo: String
        var completed: Bool
        var userId: Int
    }
    var todos: [Base]
    var total: Int
    var skip: Int
    var limit: Int
}

public protocol TaskClientInterface: Sendable {
    var testProxy: TaskClientTestProxy? { get set }
    
    func loadTasksUrl() async throws -> [TaskModel]
    func loadTasksCoreData() async throws -> [TaskModel]
    func saveTasks(tasks: [TaskModel]) async throws -> Void
    func saveTask(task: TaskModel) async throws -> Void
    func loadTask(id: Int) async throws -> TaskModel
    func searchTask(text: String?, type: TaskType, date: Date?, userId: Int?) async throws -> [TaskModel]
    func updateTask(task: TaskModel) async throws -> Void
    func createTask(task: TaskModel) async throws -> Void
    func deleteTask(id: Int) async throws -> Void
    func getAllUserIds() async throws -> [Int]
    func updateTaskCompletionStatus(id: Int, completed: Bool) async throws -> Void
}

public final class TaskClient: TaskClientInterface {
    private let taskController = CoreDataController()
    
    public func loadTasksUrl() async throws -> [TaskModel] {
        guard let url = URL(string: "https://dummyjson.com/todos") else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        let taskBaseData = try JSONDecoder().decode(TaskLoadData.self, from: data)
        return taskBaseData.todos.map {
            TaskModel(
                id: $0.id,
                title: nil,
                todo: $0.todo,
                date: nil,
                completed: $0.completed,
                userId: $0.userId
            )
        }
    }
    
    public func loadTasksCoreData() async throws -> [TaskModel] {
        return try await taskController.getAllTasks()
    }
    
    public func saveTasks(tasks: [TaskModel]) async throws {
        try await taskController.saveTasks(tasks)
    }
    
    public func saveTask(task: TaskModel) async throws {
        try await taskController.saveTask(task)
    }
    
    public func loadTask(id: Int) async throws -> TaskModel {
        try await taskController.getTask(id: Int64(id))
    }
    
    public func searchTask(text: String? = nil, type: TaskType = .all, date: Date? = nil, userId: Int? = nil) async throws -> [TaskModel] {
        try await taskController.findTasks(text: text, type: type, date: date, userId: userId)
    }
    
    public func updateTask(task: TaskModel) async throws {
        try await taskController.updateTask(taskModel: task)
    }
    
    public func createTask(task: TaskModel) async throws -> Void {
        try await taskController.createTask(taskModel: task)
    }
    
    public func deleteTask(id: Int) async throws {
        try await taskController.deleteTask(id: Int64(id))
    }
    
    public func getAllUserIds() async throws -> [Int] {
        try await taskController.getAllUserIds()
    }
    
    public func updateTaskCompletionStatus(id: Int, completed: Bool) async throws {
        try await taskController.updateTaskCompletionStatus(taskId: Int64(id), completed: completed)
    }
    
    nonisolated(unsafe) public var testProxy: TaskClientTestProxy?
    
    init() { }
}

public struct TaskClientMock: TaskClientInterface {
    
    public func loadTasksUrl() async throws -> [TaskModel] {
        try await testProxy?.loadTasksUrl() ?? [.mock]
    }
    
    public func loadTasksCoreData() async throws -> [TaskModel] {
        try await testProxy?.loadTasksCoreData() ?? [.mock]
    }
    
    public func saveTasks(tasks: [TaskModel]) async throws {
        try await testProxy?.saveTasks(tasks)
    }
    
    public func saveTask(task: TaskModel) async throws {
        try await testProxy?.saveTask(task)
    }
    
    public func loadTask(id: Int) async throws -> TaskModel {
        try await testProxy?.loadTask(id) ?? .mock
    }

    public func searchTask(text: String? = nil, type: TaskType = .all, date: Date? = nil, userId: Int? = nil) async throws -> [TaskModel] {
        try await testProxy?.searchTask(text, type, date, userId) ?? [.mock]
    }
    
    public func updateTask(task: TaskModel) async throws {
        try await testProxy?.updateTask(task)
    }
    
    public func createTask(task: TaskModel) async throws -> Void {
        try await testProxy?.createTask(task)
    }
    
    public func deleteTask(id: Int) async throws {
        try await testProxy?.deleteTask(id)
    }
    
    public func getAllUserIds() async throws -> [Int] {
        try await testProxy?.getAllUserIds() ?? []
    }
    
    public func updateTaskCompletionStatus(id: Int, completed: Bool) async throws {
        try await testProxy?.updateTaskCompletionStatus(id, completed)
    }
    
    nonisolated(unsafe) public var testProxy: TaskClientTestProxy? = TaskClientTestProxy()
}

extension TaskClient: DependencyKey {
    public static let liveValue: TaskClientInterface = TaskClient()
    public static let previewValue: TaskClientInterface = TaskClientMock()
    public static let testValue: TaskClientInterface = TaskClientMock()
}

extension DependencyValues {
    public var taskClient: TaskClientInterface {
        get { self[TaskClient.self] }
        set { self[TaskClient.self] = newValue }
    }
}

// MARK: - Test Proxy

public struct TaskClientTestProxy: Sendable {
    public var loadTasksUrl: @Sendable () async throws -> [TaskModel]
    public var loadTasksCoreData: @Sendable () async throws -> [TaskModel]
    public var saveTasks: @Sendable ([TaskModel]) async throws -> Void
    public var saveTask: @Sendable (TaskModel) async throws -> Void
    public var loadTask: @Sendable (Int) async throws -> TaskModel
    public var searchTask: @Sendable (String?, TaskType, Date?, Int?) async throws -> [TaskModel]
    public var updateTask: @Sendable (TaskModel) async throws -> Void
    public var createTask: @Sendable (TaskModel) async throws -> Void
    public var deleteTask: @Sendable (Int) async throws -> Void
    public var getAllUserIds: @Sendable () async throws -> [Int]
    public var updateTaskCompletionStatus: @Sendable (Int, Bool) async throws -> Void
    
    public init(
        loadTasksUrl: @Sendable @escaping () -> [TaskModel] = { [.mock] },
        loadTasksCoreData: @Sendable @escaping () -> [TaskModel] = { [.mock] },
        saveTasks: @Sendable @escaping ([TaskModel]) -> Void = { _ in },
        saveTask: @Sendable @escaping (TaskModel) -> Void = { _ in },
        loadTask: @Sendable @escaping (Int) -> TaskModel = { _ in .mock },
        searchTask: @Sendable @escaping (String?, TaskType, Date?, Int?) -> [TaskModel] = { _, _, _, _ in [.mock] },
        updateTask: @Sendable @escaping (TaskModel) -> Void = { _ in },
        createTask: @Sendable @escaping (TaskModel) -> Void = { _ in },
        deleteTask: @Sendable @escaping (Int) -> Void = { _ in },
        getAllUserIds: @Sendable @escaping () async throws -> [Int] = { [] },
        updateTaskCompletionStatus: @Sendable @escaping (Int, Bool) async throws -> Void = { _, _ in }
    ) {
        self.loadTasksUrl = loadTasksUrl
        self.loadTasksCoreData = loadTasksCoreData
        self.saveTasks = saveTasks
        self.saveTask = saveTask
        self.loadTask = loadTask
        self.searchTask = searchTask
        self.updateTask = updateTask
        self.createTask = createTask
        self.deleteTask = deleteTask
        self.getAllUserIds = getAllUserIds
        self.updateTaskCompletionStatus = updateTaskCompletionStatus
    }
}
