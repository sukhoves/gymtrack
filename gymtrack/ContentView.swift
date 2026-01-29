//
//  ContentView.swift
//  gymtrack
//
//  Created by Evgenii Sukhov on 28.01.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        GymView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self], inMemory: true)
}
