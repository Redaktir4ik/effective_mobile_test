import Foundation
import SwiftUI

public enum TaskType: Int, CaseIterable, Identifiable, Sendable  {
    public var id: Int { rawValue }
    case all
    case completed
    case uncompleted
    
    public var title: String {
        switch self {
        case .all:
            "Все задачи"
        case .completed:
            "Выполненные задачи"
        case .uncompleted:
            "Не выполненные задачи"
        }
    }
}

public struct TaskModel: Identifiable, Codable, Equatable, Sendable {
    public var id: Int
    public var title: String
    public var todo: String
    public var date: String
    public var completed: Bool
    public var userId: Int
    
    public var icon: String {
        if completed {
            "checkmark.circle"
        } else {
            "circle"
        }
    }
    
    public var iconColor: Color {
        if completed {
            Color.yellow
        } else {
            Color.gray
        }
    }
    
    public var textColor: Color {
        if completed {
            Color.secondary
        } else {
            Color.primary
        }
    }
    
    public var dateColor: Color {
        if completed {
            return Color.secondary
        }
        let calendar = Calendar.current
        let taskDate = DateTimeForward.stringToDate(self.date)
        let currentDate = calendar.startOfDay(for: Date.now)
        
        if taskDate < currentDate {
            return .red
        } else if taskDate > currentDate {
            return .green
        }
        
        return .orange
    }
    
    var shareContent: String {
        return """
            Задача: \(title)
            Описание: \(todo)
            Дата: \(date)
            Статус: \(completed ? "Выполнено" : "В работе")
            """
    }
    
    public init(id: Int, title: String?, todo: String, date: Date?, completed: Bool, userId: Int) {
        self.id = id
        self.title = title ?? todo
        self.todo = todo
        self.completed = completed
        self.userId = userId
        self.date = DateTimeForward.dateToString(date ?? Date.now)
    }
}

public extension TaskModel {
    static var mock: Self {
        .init(
            id: 1,
            title: "Тест задача",
            todo: "Тест описание задачи",
            date: Date.now,
            completed: false,
            userId: 123
        )
    }
    static var empty: Self {
        .init(
            id: 0,
            title: "",
            todo: "",
            date: Date.now,
            completed: false,
            userId: 0
        )
    }
}
