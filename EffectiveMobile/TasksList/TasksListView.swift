import SwiftUI
import Combine
import Foundation
import ComposableArchitecture
import SimpleToast

struct TasksListView: View {
    @AppStorage("firstLoad") var firstLoad: Bool = true
    @Bindable var store: StoreOf<TasksListFeature>
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Задачи")
                    .font(.title2)
                
                Spacer()
                
                Button {
                    store.send(.ui(.createTask))
                } label: {
                    Image(systemName: "plus.circle")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            if store.isLoading {
                VStack {
                    Spacer()
                    
                    ProgressView()
                    
                    Spacer()
                }
            } else {
                context
            }
        }
        .onAppear {
            store.send(.ui(.onAppear(firstLoad)))
            firstLoad = false
        }
        .simpleToast(
            item: $store.toast,
            options: .defaultOptions
        ) { _ in
            ToastView(
                title: store.toast?.title,
                subtitle: store.toast?.subtitle,
                type: store.toast?.type
            )
        }
        .modifier(Sheets(store: store))
    }
    
    @ViewBuilder
    private var context: some View {
        VStack {
            searchAndFilterView
            List(store.tasks) { task in
                Button {
                    store.send(.ui(.taskTapped(task)))
                } label: {
                    HStack(alignment: .top) {
                        Image(systemName: task.icon)
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(task.iconColor)
                        VStack(alignment: .leading ,spacing: 6) {
                            Text(task.title)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(task.textColor)
                                .strikethrough(task.completed, color: task.textColor)
                                .lineLimit(1)
                            Text(task.todo)
                                .font(.subheadline)
                                .foregroundStyle(task.textColor)
                                .lineLimit(2)
                            Text(task.date)
                                .font(.subheadline)
                                .foregroundStyle(task.dateColor)
                        }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .contextMenu {
                    Button {
                        store.send(.ui(.editTask(task)))
                    } label: {
                        Label("Редактировать", systemImage: "pencil")
                    }
                    
                    Button {
                        store.send(.ui(.shareTask(task)))
                    } label: {
                        Label("Поделиться", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        store.send(.ui(.deleteTask(task)))
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }
    
    @ViewBuilder
    private var searchAndFilterView: some View {
        VStack(alignment: .leading, spacing: 8) {
            SearchBarView(text: $store.filterTask.text)
            
            Button {
                store.send(.ui(.filtersTapped))
            } label: {
                HStack {
                    Text("Дополнительные фильтры")
                    Image(systemName: store.openFilters ? "chevron.down" : "chevron.up")
                    
                    Spacer()
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            if store.openFilters {
                VStack {
                    HStack {
                        Text("Тип задачи: ")
                        
                        Menu {
                            ForEach(TaskType.allCases) { type in
                                Button {
                                    store.send(.ui(.filterTaskTypeSelect(type)))
                                } label: {
                                    Text(type.title)
                                }
                            }
                        } label: {
                            Text(store.filterTask.taskType.title)
                        }
                        .menuStyle(.button)
                        .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        DatePickerOptionalView(date: $store.filterTask.date)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("Пользователи: ")
                        
                        Menu {
                            Button {
                                store.send(.ui(.userIsdSelected(nil)))
                            } label: {
                                Text("Все юзеры")
                            }
                            
                            Divider()
                            
                            ForEach(store.userIds, id: \.self) { user in
                                Button {
                                    store.send(.ui(.userIsdSelected(user)))
                                } label: {
                                    Text("Юзер №\(user)")
                                }
                            }
                        } label: {
                            if let userId = store.filterTask.userID  {
                                Text("Юзер №\(userId)")
                            } else {
                                Text("Все юзеры")
                            }
                        }
                        .menuStyle(.button)
                        .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
    }
}

fileprivate struct Sheets: ViewModifier {
    @Bindable var store: StoreOf<TasksListFeature>

    init(store: StoreOf<TasksListFeature>) {
        self.store = store
    }

    func body(content: Content) -> some View {
        content
            .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
            .sheet(item: $store.scope(state: \.destination?.details, action: \.destination.details)) { store in
                TaskDetailsView(store: store)
            }
            .fullScreenCover(item: $store.scope(state: \.destination?.edit, action: \.destination.edit)) { store in
                TaskDetailsView(store: store)
            }
    }
}

extension AlertState where Action == TasksListFeature.Action.Alert {
    nonisolated(unsafe) static let openConfirmationAlert = Self {
        TextState("Вы действительно хотите удалить данную задачу?")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("Отмена")
        }
        ButtonState(action: .confirm) {
            TextState("Да")
        }
    } message: {
        TextState("После удаления задачи востонавить её будет невозможно")
    }
}

#Preview {
    TasksListView(
        store: Store(
            initialState: TasksListFeature.State(),
            reducer: {
                TasksListFeature()
                    ._printChanges()
            }
        )
    )
}
