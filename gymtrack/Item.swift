//
//  Models.swift
//  gymtrack
//
//  Created by Evgenii Sukhov on 28.01.2026.
//

import Foundation
import SwiftData

@Model
final class ExerciseSet {
    var id: UUID
    var setNumber: Int
    var repetitions: String
    var weight: String
    var exercise: Exercise?
    
    init(setNumber: Int = 1, repetitions: String = "10", weight: String = "75 кг") {
        self.id = UUID()
        self.setNumber = setNumber
        self.repetitions = repetitions
        self.weight = weight
    }
}

@Model
final class Exercise {
    var id: UUID
    var name: String
    var isExpanded: Bool
    var repeats: [ExerciseSet]
    var workout: Workout?
    
    init(name: String = "Упражнение", isExpanded: Bool = true) {
        self.id = UUID()
        self.name = name
        self.isExpanded = isExpanded
        self.repeats = [ExerciseSet()]
    }
}

@Model
final class Workout {
    var id: UUID
    var title: String
    var isExpanded: Bool
    var exercises: [Exercise]
    var segment: String 
    
    init(title: String = "Тренировка", segment: String = "Спина", isExpanded: Bool = true) {
        self.id = UUID()
        self.title = title
        self.segment = segment
        self.isExpanded = isExpanded
        self.exercises = []
    }
}
