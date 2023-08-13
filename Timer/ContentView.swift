//
//  ContentView.swift
//  Timer
//
//  Created by Taha Chaudhry on 13/08/2023.
//

import SwiftUI
import UserNotifications
import WidgetKit

class TimerManager: ObservableObject {
    @Published var seconds: Int = 0
    @Published var selectedTime: Int = 0
    var timer: Timer?
    @Published var isTimerRunning = false
    @Published var isPaused = false
    var timerStartTime: Date?
    var scheduledNotificationTime: Date?
    var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    let timeOptions: [Int] = [5, 10, 15, 30, 60]
    
    var displayTime: String {
        let minutes = seconds / 60
        let seconds = self.seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func startTimer() {
        isTimerRunning = true
        timerStartTime = Date()
        scheduledNotificationTime = Date().addingTimeInterval(TimeInterval(seconds))
        
        if isPaused { isPaused = false }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if self.seconds > 0 {
                self.seconds -= 1
            } else {
                self.stopTimer()
            }
        }
        saveTimerState()
        scheduleLocalNotification()
    }
    
    func pauseTimer() {
        isTimerRunning = false
        isPaused = true
        timer?.invalidate()
        cancelScheduledNotification()
    }
    
    func stopTimer() {
        isTimerRunning = false
        isPaused = false
        timer?.invalidate()
        seconds = 0
        cancelScheduledNotification()
    }
    
    private func scheduleLocalNotification() {
        cancelScheduledNotification()
        
        let content = UNMutableNotificationContent()
        content.title = "Timer Completed"
        content.body = "Your timer has finished!"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: scheduledNotificationTime!.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: "TimerNotification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled successfully")
            }
        }
    }
    
    private func cancelScheduledNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["TimerNotification"])
    }
    
    func calculateElapsedTime() {
        if isTimerRunning {
            guard let startTime = timerStartTime else { return }
            let elapsedTime = Int(Date().timeIntervalSince(startTime))
            let newRemainingTime = max(0, seconds - elapsedTime)
            if newRemainingTime <= 0 {
                stopTimer()
            } else {
                seconds = newRemainingTime
            }
        }
    }
    
//    func loadSavedTimerState() {
//        if let savedSeconds = UserDefaults.standard.value(forKey: "SavedSeconds") as? Int {
//            seconds = savedSeconds
//            calculateElapsedTime()
//        }
//    }
//
//    func saveTimerState() {
//        UserDefaults.standard.set(seconds, forKey: "SavedSeconds")
//    }
    
    func loadSavedTimerState() {
        if let savedSeconds = UserDefaults(suiteName: "com.test.widgetData")?.value(forKey: "SavedSeconds") as? Int {
            seconds = savedSeconds
            calculateElapsedTime()
        }
    }
        
    func saveTimerState() {
        UserDefaults(suiteName: "com.test.widgetData")?.set(seconds, forKey: "SavedSeconds")
    }
}

struct ContentView: View {
    @StateObject var timerManager: TimerManager = TimerManager()
    
    var body: some View {
        VStack {
            Text("\(timerManager.displayTime)")
                .font(.largeTitle)
                .padding()
            
            Picker("Select Time", selection: $timerManager.selectedTime) {
                ForEach(timerManager.timeOptions, id: \.self) { time in
                    Text("\(time) s")
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            HStack {
                
                Button(action: {
                    guard timerManager.selectedTime != 0 else { return }
                    
                    if !timerManager.isTimerRunning {
                        if !timerManager.isPaused {
                            timerManager.seconds = timerManager.selectedTime
                            timerManager.startTimer()
                        } else {
                            timerManager.startTimer()
                        }
                    } else {
                        timerManager.pauseTimer()
                    }
                }) {
                    Text(timerManager.isPaused ? "Resume" : (timerManager.isTimerRunning ? "Pause" : "Start"))
                        .font(.title)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    timerManager.stopTimer()
                }) {
                    Text("Stop")
                        .font(.title)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .onAppear {
            timerManager.loadSavedTimerState()
            print(UserDefaults(suiteName: "com.test.widgetData")?.value(forKey: "SavedSeconds") as? Int)
        }
        .onDisappear {
            timerManager.saveTimerState()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            timerManager.calculateElapsedTime()
        }
        .onChange(of: timerManager.isTimerRunning) { newValue in
            if newValue {
                print(UserDefaults(suiteName: "com.test.widgetData")?.value(forKey: "SavedSeconds") as? Int)
                // Start a timer, and also trigger a widget update
//                timerManager.startTimer()
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
