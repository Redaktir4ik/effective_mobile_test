import SwiftUI
import ComposableArchitecture

struct TaskDetailsView: View {
    @Bindable var store: StoreOf<TaskDetailsFeature>
    
    init(store: StoreOf<TaskDetailsFeature>) {
        self.store = store
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    if store.isLoading {
                        VStack {
                            Spacer()
                            
                            ProgressView()
                            
                            Spacer()
                        }
                    } else {
                        if store.type == .details {
                            detailsView
                        } else {
                            editView
                        }
                        
                        Spacer()
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(store.type.title)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        Button {
                            store.send(.ui(.closeTapped))
                        } label: {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Назад")
                            }
                            .foregroundStyle(.yellow)
                            .font(.headline)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if store.type == .details {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            Button {
                                store.send(.ui(.changeTapped))
                            } label: {
                                Text("изменить")
                                    .font(.headline)
                                    .foregroundStyle(.blue)
                                    .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            Button {
                                store.send(.ui(.saveTapped))
                            } label: {
                                Text("cохранить")
                                    .font(.headline)
                                    .foregroundStyle(.green)
                                    .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .onAppear {
                    store.send(.ui(.onAppear))
                }
            }
        }
    }
    
    @ViewBuilder
    private var editView: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Заголовок задачи", text: $store.model.title)
                .textInputAutocapitalization(.never)
                .foregroundStyle(.primary)
                .font(.title.weight(.semibold))
            
            DatePicker(
                "Дата задачи",
                selection: $store.date,
                displayedComponents: [.date]
            )
            .onChange(of: store.date) {
                store.send(.ui(.dateSelected))
            }
            .font(.headline.weight(.regular))
            
            HStack {
                Picker("Кто выполняет задание", selection: $store.model.userId) {
                    ForEach(store.userIds, id: \.self) { user in
                        Text("Юзер №\(user)")
                        
                    }
                }
                .pickerStyle(.navigationLink)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .foregroundStyle(.primary)
            .font(.headline.weight(.regular))
            
            Divider()
            
            TextField("Описание задачи", text: $store.model.todo, axis: .vertical)
                .textInputAutocapitalization(.never)
                .font(.headline.weight(.regular))
            
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var detailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                store.send(.ui(.completedTapped))
            } label: {
                Image(systemName: store.model.completed ? "checkmark.square": "square")
                    .foregroundStyle(store.model.completed ? .yellow : .secondary)
                
                Text("Статус задачи")
            }
            .buttonStyle(.plain)
            .font(.headline.weight(.semibold))
            
            HStack {
                Text(store.model.title)
                    .font(.title.weight(.semibold))
                
                Spacer()
            }
            HStack {
                Text(store.model.date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("Юзер №\(store.model.userId)")
                    .font(.subheadline)
            }
            
            HStack {
                Text(store.model.todo)
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

#Preview {
    TaskDetailsView(
        store: Store(
            initialState: TaskDetailsFeature.State(id: 1, type: .create),
            reducer: {
                TaskDetailsFeature()
                    ._printChanges()
            }
        )
    )
}
