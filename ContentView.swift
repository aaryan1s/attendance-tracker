import SwiftUI

struct ContentView: View {
    @StateObject private var store = AttendanceStore()
    
    var body: some View {
        DashboardView(store: store)
    }
}
