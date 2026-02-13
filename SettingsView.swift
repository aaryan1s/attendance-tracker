import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("notificationTime") private var notificationTime = Date()
    @State private var hasPermission = false
    
    var body: some View {
        Form {
            Section(header: Text("Notifications")) {
                Toggle("Daily Reminder", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { newValue in
                        if newValue {
                            requestPermission()
                            scheduleNotification()
                        } else {
                            removeAllNotifications()
                        }
                    }
                
                if notificationsEnabled {
                    DatePicker("Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
                        .onChange(of: notificationTime) { _ in
                            scheduleNotification()
                        }
                }
            }
            
            Section(footer: Text("We will remind you to mark your attendance at this time every day.")) {
                // Empty section for spacing/footer
            }
        }
        .navigationTitle("Settings")
        .onAppear(perform: checkPermission)
    }
    
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                self.hasPermission = true
            } else if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification() {
        removeAllNotifications() // Clear old ones
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Track Attendance"
        content.body = "Don't forget to mark your classes for today!"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: "daily_attendance", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
