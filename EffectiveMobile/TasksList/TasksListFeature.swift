import ComposableArchitecture
import Foundation
import UIKit

@Reducer
public struct TasksListFeature: Sendable {
    public struct FilterTask: Equatable {
        public var text: String = ""
        public var taskType: TaskType = .all
        public var date: Date?
        public var userID: Int?
    }
    
    @Reducer(state: .equatable)
    public enum Destination {
        case alert(AlertState<TasksListFeature.Action.Alert>)
        case details(TaskDetailsFeature)
        case edit(TaskDetailsFeature)
    }
    
    
    @ObservableState
    public struct State: Equatable {
        var tasks: [TaskModel] = []
        var deleteTask: TaskModel?
        var filterTask: FilterTask = .init()
        var userIds: [Int] = []
        
        var isLoading: Bool = false
        var firstLoad: Bool = true
        var openFilters: Bool = false
        
        var date: Date = Date.now
        var toast: ToastState?
        @Presents var destination: Destination.State?
    }
    
    @CasePathable
    public enum Action: BindableAction {
        case ui(UI)
        case data(Data)
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)
        
        @CasePathable
        public enum UI {
            case onAppear(Bool)
            case taskTapped(TaskModel)
            case editTask(TaskModel)
            case shareTask(TaskModel)
            case deleteTask(TaskModel)
            case createTask
            
            case filtersTapped
            case clearFiltersTapped
            
            case filterTaskTypeSelect(TaskType)
            case userIsdSelected(Int?)
        }
        
        @CasePathable
        public enum Data {
            case loadTasksUrl(OperationStatus<[TaskModel], Error>)
            case loadTasksCoreData(OperationStatus<[TaskModel], Error>)
            case saveTasksCoreData(OperationStatus<Void, Error>)
            case searchTask(OperationStatus<[TaskModel], Error>)
            case deleteTask(OperationStatus<Void, Error>)
            case getUserIds(OperationStatus<[Int], Error>)
        }
        
        @CasePathable
        public enum Alert {
            case confirm
        }
    }

    @Dependency(\.taskClient) var taskClient

    public var body: some ReducerOf<Self> {
        BindingReducer()
            .onChange(of: \.filterTask.text) { _, _ in
                Reduce { state, _ in
                    return searchTaskByCoreData(filer: state.filterTask)
                }
            }
            .onChange(of: \.filterTask.date) { _, _ in
                Reduce { state, _ in
                    return searchTaskByCoreData(filer: state.filterTask)
                }
            }
        Reduce { state, action in
            switch action {
                // MARK: - UI
            case let .ui(uiAction):
                switch uiAction {
                case let .onAppear(firstLoad):
                    if firstLoad {
                        return loadByApi()
                    } else {
                        return loadByCoreData().merge(with: getUserIds())
                    }
                case let .taskTapped(task):
                    state.destination = .details(
                        TaskDetailsFeature.State(id: task.id, type: .details)
                    )
                    return .none
                case let .editTask(task):
                    state.destination = .edit(
                        TaskDetailsFeature.State(id: task.id, type: .edit)
                    )
                    return .none
                case let .shareTask(task):
                    shareToTelegram(message: task.shareContent)
                    return .none
                case let .deleteTask(task):
                    state.deleteTask = task
                    state.destination = .alert(.openConfirmationAlert)
                    return .none
                case .createTask:
                    state.destination = .edit(TaskDetailsFeature.State(type: .create))
                    return .none
                case .filtersTapped:
                    state.openFilters.toggle()
                    return .none
                case .clearFiltersTapped:
                    state.filterTask.date = nil
                    state.filterTask.taskType = .all
                    state.filterTask.userID = nil
                    return searchTaskByCoreData(filer: state.filterTask)
                case let .filterTaskTypeSelect(type):
                    state.filterTask.taskType = type
                    return searchTaskByCoreData(filer: state.filterTask)
                case let .userIsdSelected(userId):
                    state.filterTask.userID = userId
                    return searchTaskByCoreData(filer: state.filterTask)
                }
            case let .data(dataAction):
                switch dataAction {
                case let .loadTasksUrl(loadTasksAction):
                    switch loadTasksAction {
                    case .start:
                        state.isLoading = true
                        return .none
                    case let .complete(tasks):
                        state.isLoading = false
                        state.tasks = tasks
                        return saveByCoreData(list: tasks)
                    case let .fail(error):
                        state.toast = ToastState(
                            title: "Ошибка загрузки данных",
                            subtitle: error.localizedDescription,
                            type: .error
                        )
                        state.isLoading = false
                        return .none
                    }
                case let .loadTasksCoreData(loadTasksAction):
                    switch loadTasksAction {
                    case .start:
                        state.isLoading = true
                        return .none
                    case let .complete(tasks):
                        state.isLoading = false
                        state.tasks = tasks
                        return .none
                    case let .fail(error):
                        state.toast = ToastState(
                            title: "Ошибка загрузки данных c CoreData",
                            subtitle: error.localizedDescription,
                            type: .error
                        )
                        state.isLoading = false
                        return .none
                    }
                case let .saveTasksCoreData(saveTasksCoreAction):
                    switch saveTasksCoreAction {
                    case .start:
                        return .none
                    case .complete:
                        state.toast = ToastState(
                            title: "Успешно",
                            subtitle: "Успешное сохранение в СoreData",
                            type: .success
                        )
                        return getUserIds()
                    case let .fail(error):
                        state.toast = ToastState(
                            title: "Ошибка сохранения данных в CoreData",
                            subtitle: error.localizedDescription,
                            type: .error
                        )
                        return .none
                    }
                case let .searchTask(searchTaskAction):
                    switch searchTaskAction {
                    case .start:
                        return .none
                    case let .complete(tasks):
                        state.tasks = tasks
                        return .none
                    case let .fail(error):
                        state.toast = ToastState(
                            title: "Ошибка поиска данных",
                            subtitle: error.localizedDescription,
                            type: .error
                        )
                        return .none
                    }
                case let .deleteTask(deleteTaskAction):
                    switch deleteTaskAction {
                    case .start:
                        return .none
                    case .complete:
                        state.toast = ToastState(
                            title: "Здадача успешно удалена",
                            subtitle: "",
                            type: .success
                        )
                        return searchTaskByCoreData(filer: state.filterTask)
                    case let .fail(error):
                        state.toast = ToastState(
                            title: "Ошибка удаления задачи",
                            subtitle: error.localizedDescription,
                            type: .error
                        )
                        return .none
                    }
                case let .getUserIds(getUserIdsAction):
                    switch getUserIdsAction {
                    case .start:
                        return .none
                    case let .complete(usersID):
                        state.userIds = usersID
                        return .none
                    case let .fail(error):
                        state.toast = ToastState(
                            title: "Ошибка загрузки данных",
                            subtitle: error.localizedDescription,
                            type: .error
                        )
                        return .none
                    }
                }
            case .destination(.presented(.alert(.confirm))):
                guard let id = state.deleteTask?.id else { return .none }
                return deleteTask(id: id)
            case .binding, .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }

    private func loadByApi() -> Effect<Action> {
        return .run { send in
            do {
                await send(.data(.loadTasksUrl(.start)))
                var data = try await taskClient.loadTasksUrl()
                data.sort { $0.date > $1.date }
                await send(.data(.loadTasksUrl(.complete(data))))
            } catch {
                await send(.data(.loadTasksUrl(.fail(error))))
            }
        }
    }
    
    private func loadByCoreData() -> Effect<Action> {
        return .run { send in
            do {
                await send(.data(.loadTasksCoreData(.start)))
                var data = try await taskClient.loadTasksCoreData()
                data.sort { $0.date < $1.date }
                await send(.data(.loadTasksCoreData(.complete(data))))
            } catch {
                await send(.data(.loadTasksCoreData(.fail(error))))
            }
        }
    }
    
    private func saveByCoreData(list: [TaskModel]) -> Effect<Action> {
        return .run { send in
            do {
                await send(.data(.saveTasksCoreData(.start)))
                try await taskClient.saveTasks(tasks: list)
                await send(.data(.saveTasksCoreData(.complete(()))))
            } catch {
                await send(.data(.saveTasksCoreData(.fail(error))))
            }
        }
    }
    
    private func searchTaskByCoreData(filer: FilterTask) -> Effect<Action> {
        return .run { send in
            do {
                await send(.data(.searchTask(.start)))
                var tasks: [TaskModel] = try await taskClient.searchTask(
                    text: filer.text.isEmpty ? nil : filer.text,
                    type: filer.taskType,
                    date: filer.date,
                    userId: filer.userID
                )
                tasks.sort { $0.date < $1.date }
                await send(.data(.searchTask(.complete(tasks))))
            } catch {
                await send(.data(.searchTask(.fail(error))))
            }
        }
    }
    
    private func deleteTask(id: Int) -> Effect<Action> {
        return .run { send in
            do {
                await send(.data(.deleteTask(.start)))
                try await taskClient.deleteTask(id: id)
                await send(.data(.deleteTask(.complete(()))))
            } catch {
                await send(.data(.deleteTask(.fail(error))))
            }
        }
    }
    
    private func getUserIds() -> Effect<Action> {
        return .run { send in
            do {
                await send(.data(.getUserIds(.start)))
                let userIDS = try await taskClient.getAllUserIds()
                await send(.data(.getUserIds(.complete(userIDS))))
            } catch {
                await send(.data(.getUserIds(.fail(error))))
            }
        }
    }
    
    private func shareToTelegram(message: String) {
        guard let url = URL(string: "tg://msg?text=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Если Telegram не установлен, можно открыть через веб-версию
            guard let webUrl = URL(string: "https://t.me/?text=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
                return
            }
            UIApplication.shared.open(webUrl)
        }
    }
}
