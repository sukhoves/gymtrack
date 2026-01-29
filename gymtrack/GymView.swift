//
//  GymView.swift
//  gymtrack
//
//  Created by Evgenii Sukhov on 28.01.2026.
//

import SwiftUI
import SwiftData

// MARK: - Main View
struct GymView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.title) private var allWorkouts: [Workout]
    
    @State private var selectedSegment = 0
    let segments = ["Спина", "Грудь", "Ноги"]
    
    var workoutsForSegment: [Workout] {
        allWorkouts.filter { $0.segment == segments[selectedSegment] }
    }
    
    var body: some View {
        VStack {
            Picker("", selection: $selectedSegment) {
                ForEach(0..<segments.count, id: \.self) { index in
                    Text(segments[index])
                        .font(.headline)
                        .tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .frame(height: 48)
            .background(Color.clear)
            
            
            Spacer()
            
            TabView(selection: $selectedSegment) {
                ForEach(0..<segments.count, id: \.self) { segmentIndex in
                    ScrollView {
                        ForEach(workoutsForSegment) { workout in
                            WorkoutSection(
                                workout: workout,
                                onAddExercise: {
                                    addNewExercise(to: workout)
                                },
                                onToggleWorkoutExpanded: {
                                    toggleWorkoutExpanded(workout)
                                },
                                onAddSet: { exercise in
                                    addSet(to: exercise)
                                },
                                onRemoveSet: { exercise in
                                    removeSet(from: exercise)
                                },
                                onToggleExerciseExpanded: { exercise in
                                    toggleExerciseExpanded(exercise)
                                },
                                onDeleteWorkout: {
                                    deleteWorkout(workout)
                                },
                                canDeleteWorkout: workoutsForSegment.count > 1,
                                onDeleteExercise: { exercise in
                                    deleteExercise(exercise, from: workout)
                                },
                                canDeleteExercise: { exercise in
                                    workout.exercises.count > 1
                                }
                            )
                        }
                        
                        EmptyWorkout(onAdd: {
                            addNewWorkout(toSegment: segmentIndex)
                        })
                        
                        Spacer()
                    }
                    .tag(segmentIndex)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.smooth, value: selectedSegment)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Методы управления тренировками
    private func addNewWorkout(toSegment segment: Int) {
        let newWorkout = Workout(
            title: "Тренировка \(workoutsForSegment.count + 1)",
            segment: segments[segment]
        )
        modelContext.insert(newWorkout)
    }
    
    private func deleteWorkout(_ workout: Workout) {
        modelContext.delete(workout)
    }
    
    private func toggleWorkoutExpanded(_ workout: Workout) {
        workout.isExpanded.toggle()
    }
    
    // MARK: - Методы управления упражнениями
    private func addNewExercise(to workout: Workout) {
        let newExercise = Exercise(
            name: "Упражнение \(workout.exercises.count + 1)"
        )
        newExercise.workout = workout
        workout.exercises.append(newExercise)
    }
    
    private func deleteExercise(_ exercise: Exercise, from workout: Workout) {
        if let index = workout.exercises.firstIndex(where: { $0.id == exercise.id }) {
            for exerciseSet in exercise.repeats {
                modelContext.delete(exerciseSet)
            }
            workout.exercises.remove(at: index)
            modelContext.delete(exercise)
        }
    }
    
    private func addSet(to exercise: Exercise) {
        let newSetNumber = exercise.repeats.count + 1
        let newSet = ExerciseSet(
            setNumber: newSetNumber,
            repetitions: "10",
            weight: "75 кг"
        )
        newSet.exercise = exercise
        exercise.repeats.append(newSet)
    }
    
    private func removeSet(from exercise: Exercise) {
        guard exercise.repeats.count > 1 else { return }
        if let lastSet = exercise.repeats.last {
            modelContext.delete(lastSet)
            exercise.repeats.removeLast()
        }
        
        for (index, exerciseSet) in exercise.repeats.enumerated() {
            exerciseSet.setNumber = index + 1
        }
    }
    
    private func toggleExerciseExpanded(_ exercise: Exercise) {
        exercise.isExpanded.toggle()
    }
}

// MARK: - WorkoutSection View
struct WorkoutSection: View {
    let workout: Workout
    var onAddExercise: () -> Void
    var onToggleWorkoutExpanded: () -> Void
    var onAddSet: (Exercise) -> Void
    var onRemoveSet: (Exercise) -> Void
    var onToggleExerciseExpanded: (Exercise) -> Void
    var onDeleteWorkout: () -> Void
    var canDeleteWorkout: Bool
    var onDeleteExercise: (Exercise) -> Void
    var canDeleteExercise: (Exercise) -> Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Название тренировки", text: Binding(
                    get: { workout.title },
                    set: { workout.title = $0 }
                ))
                          .keyboardType(.default)
                          .submitLabel(.done)
                          .font(.headline)
                          .frame(width: 220)
                          .lineLimit(2)
                          .multilineTextAlignment(.leading)
                Spacer()
                Button(action: onToggleWorkoutExpanded) {
                    Image(systemName: workout.isExpanded ? "chevron.down" : "chevron.up")
                        .foregroundColor(.primary)
                        .opacity(workout.isExpanded ? 0.25 : 1)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .contextMenu {
                Button(role: .destructive) {
                    onDeleteWorkout()
                } label: {
                    Label("Удалить тренировку", systemImage: "trash")
                }
                .disabled(!canDeleteWorkout)
            }
            
            if workout.isExpanded {
                ForEach(workout.exercises) { exercise in
                    ExcCard(
                        exercise: exercise,
                        onAddSet: {
                            onAddSet(exercise)
                        },
                        onRemoveSet: {
                            onRemoveSet(exercise)
                        },
                        onToggleExpanded: {
                            onToggleExerciseExpanded(exercise)
                        }
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            onDeleteExercise(exercise)
                        } label: {
                            Label("Удалить упражнение", systemImage: "trash")
                        }
                        .disabled(!canDeleteExercise(exercise))
                    }
                }
                
                EmptyCard(onAdd: onAddExercise)
                    .padding(.bottom, 12)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - ExcCard View
struct ExcCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    let exercise: Exercise
    var onAddSet: () -> Void
    var onRemoveSet: () -> Void
    var onToggleExpanded: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Название упражнения", text: Binding(
                    get: { exercise.name },
                    set: { exercise.name = $0 }
                ))
                    .keyboardType(.default)
                    .submitLabel(.done)
                    .font(.headline)
                    .frame(width: 130)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Button(action: onToggleExpanded) {
                    Image(systemName: exercise.isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.primary)
                        .opacity(exercise.isExpanded ? 0.25 : 1)
                            
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: onRemoveSet) {
                        Image(systemName: "minus")
                            .foregroundColor(.primary)
                    }
                    .disabled(exercise.repeats.count <= 1)
                    .opacity(exercise.repeats.count <= 1 ? 0.25 : 1)
                    
                    Button(action: onAddSet) {
                        Image(systemName: "plus")
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.bottom, exercise.isExpanded ? 16 : 0)
            
            if exercise.isExpanded {
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Text("Подход")
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text("Повторения")
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text("Вес")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    
                    Divider()
                    
                    ForEach(exercise.repeats) { exerciseSet in
                        RepeatRow(exerciseSet: exerciseSet)
                        if exerciseSet.id != exercise.repeats.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.vertical, 12)
                .background(
                    Group {
                        if colorScheme == .dark {
                            Rectangle().fill(.ultraThinMaterial)
                        } else {
                            Color.white.opacity(0.8)
                        }
                    }
                )
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(.ultraThickMaterial)
        .cornerRadius(24)
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
}



// MARK: - RepeatRow View
struct RepeatRow: View {
    let exerciseSet: ExerciseSet
   
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(exerciseSet.setNumber)")
                .frame(maxWidth: .infinity, alignment: .center)
            
            TextField("Повторения", text: Binding(
                get: { exerciseSet.repetitions },
                set: { exerciseSet.repetitions = $0 }
            ))
                .multilineTextAlignment(.center)
                .keyboardType(.default)
                .submitLabel(.done)
                .frame(maxWidth: .infinity, alignment: .center)
                .cornerRadius(8)
                .padding(4)
            
            TextField("Вес", text: Binding(
                get: { exerciseSet.weight },
                set: { exerciseSet.weight = $0 }
            ))
                .multilineTextAlignment(.center)
                .keyboardType(.default)
                .submitLabel(.done)
                .frame(maxWidth: .infinity, alignment: .center)
                .cornerRadius(8)
                .padding(4)
        }
        .font(.body)
        .padding(.horizontal, 8)
    }
}

// MARK: - EmptyCard View
struct EmptyCard: View {
    var onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onAdd) {
                HStack {
                    Text("Добавить упражнение")
                        .foregroundColor(.secondary)
                    Spacer()
                    Image(systemName: "plus")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(.ultraThickMaterial)
        .cornerRadius(24)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}

// MARK: - EmptyWorkout View
struct EmptyWorkout: View {
    var onAdd: () -> Void
    
    var body: some View {
        HStack {
            Text("Добавить тренировку")
                .foregroundColor(.secondary)
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}

// MARK: - SegmentedControl
struct SegmentedControl: View {
    let items: [String]
    @Binding var selectedIndex: Int
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.primary.opacity(0.15))
                .frame(height: 42)
                .frame(maxWidth: .infinity)
                .cornerRadius(21)
            
            HStack(spacing: 0) {
                ForEach(0..<items.count, id: \.self) { index in
                    Button(action: {
                        selectedIndex = index
                    }) {
                        ZStack {
                            if index == selectedIndex {
                                Rectangle()
                                    .fill(.white.opacity(1))
                                    .frame(height: 36)
                                    .cornerRadius(21)
                                    .padding(2)
                            }
                            
                            Text(items[index])
                                .foregroundColor(
                                    index == selectedIndex ?
                                        .primary.opacity(1) :
                                        .primary.opacity(0.15)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(2)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Workout.self, Exercise.self, ExerciseSet.self], inMemory: true)
}
