import ComposableArchitecture
import Foundation

@Reducer
public struct TaskDetailsFeature: Sendable {
    public enum DetailsType: Equatable {
        case details
        case create
        case edit
        
        var title: String {
            switch self {
            case .details:
                return "Задача"
            case .create:
                return "Создание задачи"
            case .edit:
                return "Изменение задачи"
            }
        }
    }
    
    @ObservableState
    public struct State: Equatable {
        var id: Int?
        var type: DetailsType
        var model: TaskModel = .empty
        var userIds: [Int] = []
        
        var isLoading: Bool = false
        var date: Date
        
        var toast: ToastState?
        
        init(id: Int? = nil, type: DetailsType) {
            self.id = id
            self.type = type
            let calendar = Calendar.current
            self.date = calendar.startOfDay(for: Date.now)
        }
    }
    
    @CasePathable
    public enum Action: BindableAction {
        case ui(UI)
        case data(Data)
        case binding(BindingAction<State>)
        
        @CasePathable
        public enum UI {
            case onAppear
            case closeTapped
            case dateSelected
            case saveTapped
            case changeTapped
            case completedTapped
        }
        
        @CasePathable
        public enum Data {
            case loadTask(OperationStatus<TaskModel, Error>)
            case saveTask(OperationStatus<Void, Error>)
            case getUserIds(OperationStatus<[Int], Error>)
            case updateCompletionStatus(OperationStatus<Void, Error>)
        }
    }
    
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.taskClient) var taskClient

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
                // MARK: - UI
            case let .ui(uiAction):
                switch uiAction {
                case .onAppear:
                    guard let id = state.id else {
                        return getUserIds()
                    }
                    return loadTask(id: id).merge(with: getUserIds())
                case .closeTapped:
                    return .run { _ in await self.dismiss() }
                case .dateSelected:
                    state.model.date = DateTimeForward.dateToString(state.date)
                    return .none
                case .saveTapped:
                    if state.model.title.isEmpty, state.model.todo.isEmpty {
                        return .none
                    }
                    if state.type == .edit {
                        return saveTask(task: state.model)
                    }
                    return createTask(task: state.model)
                case .changeTapped:
                    state.type = .edit
                    return .none
                case .completedTapped:
                    let completed = !state.model.completed
                    state.model.completed = completed
                    return updateTaskCompletionStatus(id: state.model.id, completed: completed)
                }
            case let .data(dataAction):
                switch dataAction {
                case let .loadTask(loadTasksAction):
                    switch loadTasksAction {
                    case .start:
                        state.isLoading = true
                        return .none
                    case let .complete(model):
                        state.isLoading = false
                        state.model = model
                        state.date = DateTimeForward.stringToDate(model.date)
                        return .none
                    case let .fail(error):
                        state.toast = ToastState(
                            title: "Ошибка загрузки данных",
                            subtitle: error.localizedDescription,
                            type: .error
                        )
                        state.isLoading = false
                        return .none
                    }
                case let .saveTask(saveTaskAction):
                    switch saveTaskAction {
                    case .start:
                        return .none
                    case .complete:
                        return .run { _ in await self.dismiss() }
                    case let .fail(error):
                        state.toast = ToastState(
                            title: "Ошибка загрузки данных",
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
                        if state.type == .create, usersID.count > 0 {
                            state.model.userId = usersID[0]
                        }
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
                case let .updateCompletionStatus(updateCompletionStatusAction):
                    switch updateCompletionStatusAction {
                    case .start:
                        return .none
                    case .complete:
                        return .none
                    case let .fail(error):
                        state.toast = ToastState(
                            title: "Ошибка обновление статуса",
                            subtitle: error.localizedDescription,
                            type: .error
                        )
                        return .none
                    }
                }
            case .binding:
                return .none
            }
        }
    }

    private func loadTask(id: Int) -> Effect<Action> {
        return .run { send in
            do {
                await send(.data(.loadTask(.start)))
                let model = try await taskClient.loadTask(id: id)
                await send(.data(.loadTask(.complete(model))))
            } catch {
                await send(.data(.loadTask(.fail(error))))
            }
        }
    }
    
    private func saveTask(task: TaskModel) -> Effect<Action> {
        return .run { send in
            do {
                await send(.data(.saveTask(.start)))
                try await taskClient.updateTask(task: task)
                await send(.data(.saveTask(.complete(()))))
            } catch {
                await send(.data(.saveTask(.fail(error))))
            }
        }
    }
    
    private func createTask(task: TaskModel) -> Effect<Action> {
        return .run { send in
            do {
                await send(.data(.saveTask(.start)))
                try await taskClient.createTask(task: task)
                await send(.data(.saveTask(.complete(()))))
            } catch {
                await send(.data(.saveTask(.fail(error))))
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
    
    private func updateTaskCompletionStatus(id: Int, completed: Bool) -> Effect<Action> {
        return .run { send in
            do {
                await send(.data(.updateCompletionStatus(.start)))
                try await taskClient.updateTaskCompletionStatus(id: id, completed: completed)
                await send(.data(.updateCompletionStatus(.complete(()))))
            } catch {
                await send(.data(.updateCompletionStatus(.fail(error))))
            }
        }
    }
}
