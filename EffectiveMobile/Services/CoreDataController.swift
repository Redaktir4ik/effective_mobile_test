import CoreData

struct CoreDataController {
    let container: NSPersistentContainer
    
    func getAllTasks() async throws -> [TaskModel] {
        let context = container.viewContext
        return try await context.perform {
            let request: NSFetchRequest<Tasks> = Tasks.fetchRequest()
            let results = try context.fetch(request)
            
            return results.map { task in
                TaskModel(
                    id: Int(task.id),
                    title: task.title,
                    todo: task.todo ?? "",
                    date: task.date,
                    completed: task.completed,
                    userId: Int(task.userId)
                )
            }
        }
    }
    
    func getTask(id: Int64) async throws -> TaskModel {
        let context = container.viewContext
        
        return try await context.perform {
            // Создаем запрос для поиска задачи
            let fetchRequest: NSFetchRequest<Tasks> = Tasks.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %d", id)
            
            // Находим задачу
            guard let task = try context.fetch(fetchRequest).first else {
                throw NSError(domain: "DeleteError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Задача не найдена"])
            }
            
            return TaskModel(
                id: Int(task.id),
                title: task.title,
                todo: task.todo ?? "",
                date: task.date,
                completed: task.completed,
                userId: Int(task.userId)
            )
        }
    }
    
    func saveTasks(_ tasks: [TaskModel]) async throws {
        let context = container.viewContext
        
        try await context.perform {
            for taskModel in tasks {
                let task = Tasks(context: context)
                task.id = Int64(taskModel.id)
                task.title = taskModel.title
                task.todo = taskModel.todo
                task.date = DateTimeForward.stringToDate(taskModel.date)
                task.completed = taskModel.completed
                task.userId = Int64(taskModel.userId)
            }
            
            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    func saveTask(_ taskModel: TaskModel) async throws {
        let context = container.viewContext
        try await context.perform {
            let task = Tasks(context: context)
            task.id = Int64(taskModel.id)
            task.title = taskModel.title
            task.todo = taskModel.todo
            task.date = DateTimeForward.stringToDate(taskModel.date)
            task.completed = taskModel.completed
            task.userId = Int64(taskModel.userId)
            try context.save()
        }
    }
    
    func createTask(taskModel: TaskModel) async throws {
        let context = container.viewContext
        
        return try await context.perform {
            // Создаем новую сущность
            let newTask = Tasks(context: context)
            
            // Генерируем уникальный ID
            let maxId = try context.fetch(Tasks.fetchRequest())
                .compactMap { Int($0.id) }
                .max() ?? 0
            
            newTask.id = Int64(maxId + 1)
            newTask.title = taskModel.title
            newTask.todo = taskModel.todo
            newTask.date = DateTimeForward.stringToDate(taskModel.date)
            newTask.completed = taskModel.completed
            newTask.userId = Int64(taskModel.userId)
            try context.save()
        }
    }
    
    func updateTask(taskModel: TaskModel) async throws {
        // 1. Создаем контекст и запрос на поиск
        let context = container.viewContext
        try await context.perform {
            let fetchRequest: NSFetchRequest<Tasks> = Tasks.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %d", Int64(taskModel.id))
            
            // 2. Выполняем поиск
            guard let task = try context.fetch(fetchRequest).first else {
                throw NSError(domain: "UpdateError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Задача не найдена"])
            }
            
            task.title = taskModel.title
            task.todo = taskModel.todo
            task.date = DateTimeForward.stringToDate(taskModel.date)
            task.completed = taskModel.completed
            task.userId = Int64(taskModel.userId)
            
            // 5. Сохраняем изменения
            try context.save()
        }
    }
    
    func deleteTask(id: Int64) async throws {
        let context = container.viewContext
       
        try await context.perform {
            // Создаем запрос для поиска задачи
            let fetchRequest: NSFetchRequest<Tasks> = Tasks.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %d", id)
            
            // Находим задачу
            guard let task = try context.fetch(fetchRequest).first else {
                throw NSError(domain: "DeleteError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Задача не найдена"])
            }
            
            // Удаляем задачу
            context.delete(task)
            
            // Сохраняем изменения
            try context.save()
        }
    }
    
    func findTasks(text: String? = nil, type: TaskType = .all, date: Date? = nil, userId: Int? = nil) async throws -> [TaskModel] {
        let context = container.viewContext
        
        return try await context.perform {
            // Создаем запрос
            let fetchRequest: NSFetchRequest<Tasks> = Tasks.fetchRequest()
            
            // Массив для хранения предикатов
            var predicateArray: [NSPredicate] = []
            
            // Создаем предикаты для title и todo с OR условием
            if let text = text {
                let titlePredicate = NSPredicate(format: "title CONTAINS[c] %@", text)
                let todoPredicate = NSPredicate(format: "todo CONTAINS[c] %@", text)
                let orPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [titlePredicate, todoPredicate])
                predicateArray.append(orPredicate)
            }
            
            // Добавляем предикат для типа задачи
            switch type {
            case .completed:
                predicateArray.append(NSPredicate(format: "completed == TRUE"))
            case .uncompleted:
                predicateArray.append(NSPredicate(format: "completed == FALSE"))
            default:
                // Для .all ничего не добавляем
                break
            }
            
            // Добавляем остальные предикаты с AND условием
            if let date = date {
                predicateArray.append(NSPredicate(format: "date >= %@", date as CVarArg))
            }
            
            if let userId = userId {
                predicateArray.append(NSPredicate(format: "userId == %d", userId))
            }
            
            // Создаем финальный предикат
            if !predicateArray.isEmpty {
                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicateArray)
            }
            
            // Выполняем поиск
            let results = try context.fetch(fetchRequest)
            
            // Конвертируем результаты
            return results.map { task in
                TaskModel(
                    id: Int(task.id),
                    title: task.title,
                    todo: task.todo ?? "",
                    date: task.date,
                    completed: task.completed,
                    userId: Int(task.userId)
                )
            }
        }
    }
    
    func getAllUserIds() async throws -> [Int] {
        let context = container.viewContext
        
        return try await context.perform {
            // Создаем запрос для выборки
            let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Tasks")
            
            // Настраиваем параметры запроса
            request.resultType = NSFetchRequestResultType.dictionaryResultType
            request.returnsDistinctResults = true
            request.propertiesToFetch = ["userId"]
            
            // Выполняем запрос
            let results = try context.fetch(request) as! [[String: Any]]
            
            // Преобразуем результаты в массив Int
            return results.compactMap { dict -> Int? in
                guard let userId = dict["userId"] as? Int64 else { return nil }
                return Int(userId)
            }
        }
    }
    
    func updateTaskCompletionStatus(taskId: Int64, completed: Bool) async throws {
        let context = container.viewContext
        
        try await context.perform {
            // Создаем запрос для поиска задачи
            let fetchRequest: NSFetchRequest<Tasks> = Tasks.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %d", taskId)
            
            // Находим задачу
            guard let task = try context.fetch(fetchRequest).first else { return }
            
            // Обновляем статус
            task.completed = completed
            
            // Сохраняем изменения
            try context.save()
        }
    }

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "EffectiveMobile")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
