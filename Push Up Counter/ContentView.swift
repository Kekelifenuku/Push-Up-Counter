import SwiftUI
import AVFoundation
import UserNotifications
import Combine
import StoreKit

// MARK: - App Delegate for Notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}



// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var viewModel: PushUpViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Label("Workout", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(1)
            
            AchievementsView()
                .tabItem {
                    Label("Achievements", systemImage: "trophy.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .accentColor(.white)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var viewModel: PushUpViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient Background
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: spacing(for: geometry)) {
                        // Top Header
                        headerSection(for: geometry)
                        
                        // Timer Mode Picker
                        timerModePicker(for: geometry)
                        
                        // Goal Progress Bar
                        if viewModel.dailyGoal > 0 {
                            goalProgressView(for: geometry)
                        }
                        
                        // Timer Display based on mode
                        timerSection(for: geometry)
                        
                        // Main Counter Circle
                        counterDisplay(for: geometry)
                        
                        // Achievements Badge
                        if viewModel.hasNewAchievement {
                            achievementBadge(for: geometry)
                        }
                        
                        // Action Buttons
                        actionButtons(for: geometry)
                        
                        // Statistics Cards
                        statisticsSection(for: geometry)
                        
                        // Bottom spacing for tab bar
                        Spacer(minLength: isIPad(geometry) ? 100 : 90)
                    }
                    .padding(padding(for: geometry))
                }
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.2, green: 0.3, blue: 0.5),
                Color(red: 0.4, green: 0.2, blue: 0.5)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    private func headerSection(for geometry: GeometryProxy) -> some View {
        HStack {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.title)
                .foregroundColor(.white)
            
            Text("Push Up Counter")
                .font(isIPad(geometry) ? .largeTitle : .title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
    
    // MARK: - Timer Mode Picker
    private func timerModePicker(for geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            Button(action: {
                viewModel.timerMode = .stopwatch
            }) {
                VStack(spacing: 4) {
                    Text("Stopwatch")
                        .font(.caption.bold())
                        .foregroundColor(viewModel.timerMode == .stopwatch ? .white : .white.opacity(0.6))
                    
                    if viewModel.timerMode == .stopwatch {
                        Capsule()
                            .fill(Color.white)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            
            Button(action: {
                viewModel.timerMode = .counter
            }) {
                VStack(spacing: 4) {
                    Text("Counter Timer")
                        .font(.caption.bold())
                        .foregroundColor(viewModel.timerMode == .counter ? .white : .white.opacity(0.6))
                    
                    if viewModel.timerMode == .counter {
                        Capsule()
                            .fill(Color.white)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.1))
        )
    }
    
    // MARK: - Goal Progress
    private func goalProgressView(for geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Daily Goal")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("\(viewModel.todayTotal) / \(viewModel.dailyGoal)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
            
            GeometryReader { progressGeo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.2))
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.green, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressGeo.size.width * min(viewModel.goalProgress, 1.0))
                }
            }
            .frame(height: isIPad(geometry) ? 12 : 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.1))
        )
    }
    
 
    // MARK: - Timer Section
    private func timerSection(for geometry: GeometryProxy) -> some View {
        VStack(spacing: isIPad(geometry) ? 24 : 16) {
            // Main Timer Display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if viewModel.timerMode == .stopwatch {
                        Text("Session Time")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(viewModel.formattedSessionTime)
                            .font(.system(size: isIPad(geometry) ? 32 : 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    } else {
                        Text("Counter Timer")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(viewModel.formattedCounterTimer)
                            .font(.system(size: isIPad(geometry) ? 32 : 24, weight: .bold, design: .monospaced))
                            .foregroundColor(viewModel.isCounterTimerRunning ? .green : .white)
                    }
                }
                
                Spacer()
                
                // Timer Controls
                if viewModel.timerMode == .stopwatch {
                    Button(action: {
                        viewModel.toggleStopwatch()
                    }) {
                        Image(systemName: viewModel.isTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: isIPad(geometry) ? 36 : 28))
                            .foregroundColor(.white)
                            .frame(width: isIPad(geometry) ? 50 : 40, height: isIPad(geometry) ? 50 : 40)
                    }
                } else {
                    HStack(spacing: isIPad(geometry) ? 24 : 16) {
                        // Counter Timer Controls
                        Button(action: {
                            viewModel.resetCounterTimer()
                        }) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: isIPad(geometry) ? 26 : 20))
                                .foregroundColor(.orange)
                                .frame(width: isIPad(geometry) ? 40 : 32, height: isIPad(geometry) ? 40 : 32)
                        }
                        
                        Button(action: {
                            viewModel.toggleCounterTimer()
                        }) {
                            Image(systemName: viewModel.isCounterTimerRunning ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: isIPad(geometry) ? 36 : 28))
                                .foregroundColor(viewModel.isCounterTimerRunning ? .green : .white)
                                .frame(width: isIPad(geometry) ? 50 : 40, height: isIPad(geometry) ? 50 : 40)
                        }
                    }
                }
            }
            .padding(.bottom, 4)
            
            // Counter Timer Settings Row
            if viewModel.timerMode == .counter {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Set Time")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.leading, 2)
                    
                    HStack(spacing: 0) {
                        // Minutes Section
                        VStack(spacing: 6) {
                            Text("Minutes")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    viewModel.decreaseCounterTimer(minutes: 1)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.red)
                                        .frame(width: 32, height: 32)
                                }
                                
                                VStack(spacing: 2) {
                                    Text("\(viewModel.counterTimerMinutes)")
                                        .font(.system(size: isIPad(geometry) ? 32 : 26, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .frame(width: 50)
                                    
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(height: 2)
                                        .frame(width: 40)
                                }
                                
                                Button(action: {
                                    viewModel.increaseCounterTimer(minutes: 1)
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.green)
                                        .frame(width: 32, height: 32)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Separator
                        VStack {
                            Spacer()
                            Text(":")
                                .font(.system(size: isIPad(geometry) ? 32 : 26, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                            Spacer()
                        }
                        .frame(width: 20)
                        
                        // Seconds Section
                        VStack(spacing: 6) {
                            Text("Seconds")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    viewModel.decreaseCounterTimer(seconds: 10)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.red)
                                        .frame(width: 32, height: 32)
                                }
                                
                                VStack(spacing: 2) {
                                    Text("\(String(format: "%02d", viewModel.counterTimerSeconds))")
                                        .font(.system(size: isIPad(geometry) ? 32 : 26, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                        .frame(width: 50)
                                    
                                    Rectangle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(height: 2)
                                        .frame(width: 40)
                                }
                                
                                Button(action: {
                                    viewModel.increaseCounterTimer(seconds: 10)
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.green)
                                        .frame(width: 32, height: 32)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, isIPad(geometry) ? 24 : 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )
                }
                .padding(.top, 4)
            }
            
            // Rest Timer (if active)
            if viewModel.isRestTimerActive {
                HStack {
                    Image(systemName: "timer")
                        .font(.title3)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rest Timer")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange.opacity(0.9))
                        
                        Text("Time to recover before next set")
                            .font(.caption2)
                            .foregroundColor(.orange.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text(viewModel.formattedRestTime)
                        .font(.system(size: isIPad(geometry) ? 24 : 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                        .frame(minWidth: 60)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.orange.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
        .padding(isIPad(geometry) ? 20 : 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Counter Display
    private func counterDisplay(for geometry: GeometryProxy) -> some View {
        ZStack {
            // Outer ring for streak
            if viewModel.currentStreak > 1 {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isIPad(geometry) ? 8 : 6
                    )
                    .frame(width: circleSize(for: geometry) + 20, height: circleSize(for: geometry) + 20)
            }
            
            VStack(spacing: 16) {
                // Streak indicator
                if viewModel.currentStreak > 1 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(viewModel.currentStreak) day streak")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                    }
                }
                
                Text("\(viewModel.currentCount)")
                    .font(.system(size: fontSize(for: geometry), weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.currentCount)
                
                Text(viewModel.currentCount == 1 ? "Push Up" : "Push Ups")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                
                // Reps per minute (only for stopwatch mode)
                if viewModel.timerMode == .stopwatch && viewModel.repsPerMinute > 0 {
                    Text("\(viewModel.repsPerMinute) RPM")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
                
                // Counter Timer Progress (only for counter mode)
                if viewModel.timerMode == .counter && viewModel.counterTimerTotalSeconds > 0 {
                    VStack(spacing: 4) {
                        ProgressView(value: viewModel.counterTimerProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .frame(width: circleSize(for: geometry) * 0.6)
                        
                        Text(viewModel.formattedCounterTimeRemaining)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(width: circleSize(for: geometry), height: circleSize(for: geometry))
            .background(
                Circle()
                    .fill(.white.opacity(0.15))
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.3), lineWidth: 2)
                    )
            )
        }
    }
    
    // MARK: - Achievement Badge
    private func achievementBadge(for geometry: GeometryProxy) -> some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            Text("New Achievement Unlocked!")
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.yellow.opacity(0.3))
                .overlay(
                    Capsule()
                        .stroke(.yellow, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Action Buttons
    private func actionButtons(for geometry: GeometryProxy) -> some View {
        HStack(spacing: buttonSpacing(for: geometry)) {
            // Minus Button
            CircleButton(
                icon: "minus",
                color: .red,
                size: smallButtonSize(for: geometry),
                isDisabled: viewModel.currentCount == 0
            ) {
                viewModel.decrement()
            }
            
            // Main Add Button
            CircleButton(
                icon: "plus",
                color: .green,
                size: largeButtonSize(for: geometry),
                isPrimary: true
            ) {
                viewModel.increment()
            }
            
            // Quick Add 5
            CircleButton(
                icon: "5.circle.fill",
                color: .blue,
                size: smallButtonSize(for: geometry)
            ) {
                viewModel.quickAdd(5)
            }
            
            // Reset Session Button
            CircleButton(
                icon: "arrow.counterclockwise",
                color: .orange,
                size: smallButtonSize(for: geometry),
                isDisabled: viewModel.currentCount == 0
            ) {
                viewModel.resetSession()
            }
        }
    }
    
    // MARK: - Statistics Section
    private func statisticsSection(for geometry: GeometryProxy) -> some View {
        VStack(spacing: cardSpacing(for: geometry)) {
            HStack(spacing: cardSpacing(for: geometry)) {
                StatsCard(
                    title: "Best",
                    value: "\(viewModel.personalBest)",
                    icon: "trophy.fill",
                    color: .yellow,
                    geometry: geometry
                )
                
                StatsCard(
                    title: "Total",
                    value: "\(viewModel.totalPushUps)",
                    icon: "sum",
                    color: .blue,
                    geometry: geometry
                )
                
                StatsCard(
                    title: "Sessions",
                    value: "\(viewModel.sessionsCompleted)",
                    icon: "calendar",
                    color: .purple,
                    geometry: geometry
                )
            }
            
            HStack(spacing: cardSpacing(for: geometry)) {
                StatsCard(
                    title: "Today",
                    value: "\(viewModel.todayTotal)",
                    icon: "sun.max.fill",
                    color: .orange,
                    geometry: geometry
                )
                
                StatsCard(
                    title: "This Week",
                    value: "\(viewModel.weekTotal)",
                    icon: "calendar.badge.clock",
                    color: .green,
                    geometry: geometry
                )
                
                StatsCard(
                    title: "Average",
                    value: "\(viewModel.averagePerSession)",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .cyan,
                    geometry: geometry
                )
            }
        }
    }
    
    // MARK: - Adaptive Sizing Helpers
    private func isIPad(_ geometry: GeometryProxy) -> Bool {
        geometry.size.width > 768
    }
    
    private func fontSize(for geometry: GeometryProxy) -> CGFloat {
        isIPad(geometry) ? 120 : 90
    }
    
    private func circleSize(for geometry: GeometryProxy) -> CGFloat {
        isIPad(geometry) ? 360 : 260
    }
    
    private func smallButtonSize(for geometry: GeometryProxy) -> CGFloat {
        isIPad(geometry) ? 80 : 65
    }
    
    private func largeButtonSize(for geometry: GeometryProxy) -> CGFloat {
        isIPad(geometry) ? 110 : 90
    }
    
    private func buttonSpacing(for geometry: GeometryProxy) -> CGFloat {
        isIPad(geometry) ? 20 : 12
    }
    
    private func cardSpacing(for geometry: GeometryProxy) -> CGFloat {
        isIPad(geometry) ? 16 : 12
    }
    
    private func spacing(for geometry: GeometryProxy) -> CGFloat {
        isIPad(geometry) ? 24 : 16
    }
    
    private func padding(for geometry: GeometryProxy) -> CGFloat {
        isIPad(geometry) ? 32 : 20
    }
}

// MARK: - Circle Button Component
struct CircleButton: View {
    let icon: String
    let color: Color
    let size: CGFloat
    var isPrimary: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            action()
            animatePress()
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(isDisabled ? 0.3 : 0.8),
                                color.opacity(isDisabled ? 0.2 : 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                    .shadow(
                        color: isDisabled ? .clear : color.opacity(0.4),
                        radius: isPrimary ? 20 : 10,
                        x: 0,
                        y: isPrimary ? 8 : 4
                    )
                
                Image(systemName: icon)
                    .font(.system(size: size * (isPrimary ? 0.4 : 0.32), weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .disabled(isDisabled)
    }
    
    private func animatePress() {
        isPressed = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isPressed = false
        }
    }
}

// MARK: - Stats Card Component
struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let geometry: GeometryProxy
    
    private var isIPad: Bool {
        geometry.size.width > 768
    }
    
    var body: some View {
        VStack(spacing: isIPad ? 8 : 6) {
            Image(systemName: icon)
                .font(.system(size: isIPad ? 22 : 18))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: isIPad ? 28 : 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
            
            Text(title)
                .font(.system(size: isIPad ? 13 : 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isIPad ? 16 : 12)
        .padding(.horizontal, isIPad ? 12 : 8)
        .background(
            RoundedRectangle(cornerRadius: isIPad ? 16 : 12)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: isIPad ? 16 : 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var viewModel: PushUpViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section("Daily Goal") {
                    Stepper("Goal: \(viewModel.dailyGoal) push-ups", value: $viewModel.dailyGoal, in: 0...1000, step: 10)
                }
                
                Section("Timer Settings") {
                    Picker("Default Timer Mode", selection: $viewModel.timerMode) {
                        Text("Stopwatch").tag(TimerMode.stopwatch)
                        Text("Counter Timer").tag(TimerMode.counter)
                    }
                    
                    Toggle("Auto Rest Timer", isOn: $viewModel.autoRestTimer)
                    if viewModel.autoRestTimer {
                        Stepper("Rest Duration: \(viewModel.restDuration)s", value: $viewModel.restDuration, in: 10...300, step: 10)
                    }
                }
                
                Section("Sound Effects") {
                    Toggle("Enable Sound Effects", isOn: $viewModel.soundEnabled)
                    Toggle("Enable Voice Count", isOn: $viewModel.voiceCountEnabled)
                }
                
                Section("Notifications") {
                    Toggle("Daily Reminders", isOn: $viewModel.dailyRemindersEnabled)
                        .onChange(of: viewModel.dailyRemindersEnabled) { newValue in
                            if newValue {
                                viewModel.scheduleDailyReminders()
                            } else {
                                viewModel.cancelDailyReminders()
                            }
                        }
                    
                    if viewModel.dailyRemindersEnabled {
                        DatePicker("Reminder Time", selection: $viewModel.reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: viewModel.reminderTime) { _ in
                                viewModel.scheduleDailyReminders()
                            }
                    }
                    
                    Toggle("Milestone Notifications", isOn: $viewModel.milestoneNotificationsEnabled)
                    Toggle("Goal Achievement Alerts", isOn: $viewModel.goalNotificationsEnabled)
                    Toggle("Streak Reminders", isOn: $viewModel.streakRemindersEnabled)
                    
                    Button("Test Notification") {
                        viewModel.sendTestNotification()
                    }
                }
                
                Section("Data") {
                    Button("Export History") {
                        viewModel.exportHistory()
                    }
                    Button("Reset All Data", role: .destructive) {
                        viewModel.resetAll()
                    }
                }
                Section("Connect") {

                    // ⭐ Rate App
                    Button {
                        if let scene = UIApplication.shared.connectedScenes
                            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                            SKStoreReviewController.requestReview(in: scene)
                        }
                    } label: {
                        Label("Rate App", systemImage: "star.fill")
                    }

                    // 📤 Share App
                    ShareLink(
                        item: URL(string: "https://apps.apple.com/app/id6758590012")!
                    ) {
                        Label("Share App", systemImage: "square.and.arrow.up")
                    }

                    // 🌐 Website
                    Link(destination: URL(string: "https://appgallery.io/Keli")!) {
                        Label("Visit Website", systemImage: "globe")
                    }

                    // 🐞 Report Bug
                    Link(
                        destination: URL(
                            string: "mailto:fenuku.kekeli8989@gmail.com?subject=Bug%20Report"
                        )!
                    ) {
                        Label("Report a Bug 🐞", systemImage: "envelope.fill")
                    }
                }

            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - History View
struct HistoryView: View {
    @EnvironmentObject var viewModel: PushUpViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.3, blue: 0.5),
                        Color(red: 0.4, green: 0.2, blue: 0.5)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if viewModel.sessionHistory.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("No Workout History Yet")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Complete your first workout session to see it here!")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(viewModel.sessionHistory) { session in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(session.count) push-ups")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Text(session.date, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(session.formattedDuration)
                                            .font(.headline)
                                            .foregroundColor(.cyan)
                                        
                                        Text("Duration")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    if session.count == viewModel.personalBest {
                                        Image(systemName: "crown.fill")
                                            .font(.title3)
                                            .foregroundColor(.yellow)
                                            .padding(.leading, 8)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deleteSession)
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func deleteSession(at offsets: IndexSet) {
        viewModel.deleteSession(at: offsets)
    }
}

// MARK: - Achievements View
struct AchievementsView: View {
    @EnvironmentObject var viewModel: PushUpViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.2, green: 0.3, blue: 0.5),
                        Color(red: 0.4, green: 0.2, blue: 0.5)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                        ForEach(viewModel.achievements) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Achievement Card Component
struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ?
                          LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom) :
                          LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(achievement.isUnlocked ? Color.yellow : Color.gray.opacity(0.5), lineWidth: 2)
                    )
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 36))
                    .foregroundColor(achievement.isUnlocked ? .white : .gray.opacity(0.7))
            }
            
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                if achievement.isUnlocked {
                    Text("Unlocked!")
                        .font(.caption2.bold())
                        .foregroundColor(.green)
                        .padding(.top, 4)
                } else {
                    Text("\(achievement.currentProgress)/\(achievement.targetProgress)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Models
enum TimerMode {
    case stopwatch
    case counter
}

struct WorkoutSession: Identifiable, Codable, Equatable {
    let id: UUID
    let count: Int
    let date: Date
    let duration: TimeInterval
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let targetProgress: Int
    var currentProgress: Int
    var isUnlocked: Bool {
        currentProgress >= targetProgress
    }
}

// MARK: - Notification Manager
class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func scheduleDailyReminder(at time: Date) {
        center.removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
        
        let content = UNMutableNotificationContent()
        content.title = "Time for Push-Ups! 💪"
        content.body = "Don't break your streak! Let's do some push-ups today."
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        center.add(request)
    }
    
    func cancelDailyReminders() {
        center.removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
    }
    
    func sendMilestoneNotification(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Milestone Reached! 🎉"
        content.body = "Congratulations! You've completed \(count) push-ups!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        center.add(request)
    }
    
    func sendGoalAchievedNotification(goal: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Goal Achieved! 🏆"
        content.body = "Amazing! You've reached your daily goal of \(goal) push-ups!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        center.add(request)
    }
    
    func sendStreakReminderNotification(streak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Keep Your Streak Alive! 🔥"
        content.body = "You're on a \(streak) day streak! Don't break it now!"
        content.sound = .default
        
        var components = DateComponents()
        components.hour = 20
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "streakReminder", content: content, trigger: trigger)
        
        center.add(request)
    }
    
    func sendAchievementNotification(title: String) {
        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked! ⭐"
        content.body = "You've earned the '\(title)' achievement!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        center.add(request)
    }
    
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Notifications are working perfectly! 👍"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        center.add(request)
    }
    
    func sendCounterTimerFinishedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Timer Finished! ⏰"
        content.body = "Your push-up timer has finished!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "counterTimerFinished", content: content, trigger: trigger)
        
        center.add(request)
    }
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

// MARK: - View Model
class PushUpViewModel: ObservableObject {
    // Counter
    @Published var currentCount: Int = 0
    @Published var personalBest: Int = 0
    @Published var totalPushUps: Int = 0
    @Published var sessionsCompleted: Int = 0
    
    // Goals & Progress
    @Published var dailyGoal: Int = 50
    @Published var todayTotal: Int = 0
    @Published var weekTotal: Int = 0
    @Published var currentStreak: Int = 0
    
    // Timer Modes
    @Published var timerMode: TimerMode = .stopwatch
    
    // Stopwatch Timer
    @Published var sessionTime: TimeInterval = 0
    @Published var isTimerRunning: Bool = false
    
    // Counter Timer
    @Published var counterTimerMinutes: Int = 1
    @Published var counterTimerSeconds: Int = 0
    @Published var isCounterTimerRunning: Bool = false
    @Published var counterTimerElapsed: TimeInterval = 0
    
    // Rest Timer
    @Published var isRestTimerActive: Bool = false
    @Published var restTime: TimeInterval = 0
    
    // Settings
    @Published var soundEnabled: Bool = true
    @Published var voiceCountEnabled: Bool = false
    @Published var autoRestTimer: Bool = false
    @Published var restDuration: Int = 60
    
    // Notification Settings
    @Published var dailyRemindersEnabled: Bool = false
    @Published var reminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var milestoneNotificationsEnabled: Bool = true
    @Published var goalNotificationsEnabled: Bool = true
    @Published var streakRemindersEnabled: Bool = true
    
    // History & Achievements
    @Published var sessionHistory: [WorkoutSession] = []
    @Published var achievements: [Achievement] = []
    @Published var hasNewAchievement: Bool = false
    
    private let hapticManager = HapticFeedbackManager()
    private let soundManager = SoundManager()
    private let notificationManager = NotificationManager.shared
    private let storage = UserDefaults.standard
    private var stopwatchTimer: Timer?
    private var counterTimer: Timer?
    private var restTimer: Timer?
    private var sessionStartTime: Date?
    private var counterTimerStartTime: Date?
    private var repTimes: [Date] = []
    private var goalAchievedToday: Bool = false
    private var lastWorkoutDate: Date?
    
    // Computed Properties
    var goalProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return Double(todayTotal) / Double(dailyGoal)
    }
    
    var formattedSessionTime: String {
        let minutes = Int(sessionTime) / 60
        let seconds = Int(sessionTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedCounterTimer: String {
        if isCounterTimerRunning {
            let remaining = max(0, counterTimerTotalSeconds - Int(counterTimerElapsed))
            let minutes = remaining / 60
            let seconds = remaining % 60
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return String(format: "%d:%02d", counterTimerMinutes, counterTimerSeconds)
        }
    }
    
    var formattedCounterTimeRemaining: String {
        let remaining = max(0, counterTimerTotalSeconds - Int(counterTimerElapsed))
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d remaining", minutes, seconds)
    }
    
    var formattedRestTime: String {
        let seconds = Int(restTime)
        return "\(seconds)s"
    }
    
    var repsPerMinute: Int {
        guard sessionTime > 0, currentCount > 0 else { return 0 }
        return Int((Double(currentCount) / sessionTime) * 60)
    }
    
    var averagePerSession: Int {
        guard sessionsCompleted > 0 else { return 0 }
        return totalPushUps / sessionsCompleted
    }
    
    var counterTimerProgress: Double {
        let totalDuration = TimeInterval(counterTimerTotalSeconds)
        guard totalDuration > 0 else { return 0 }
        return min(counterTimerElapsed / totalDuration, 1.0)
    }
    
    var counterTimerTotalSeconds: Int {
        counterTimerMinutes * 60 + counterTimerSeconds
    }
    
    // Storage Keys
    private enum StorageKey {
        static let personalBest = "personalBest"
        static let totalPushUps = "totalPushUps"
        static let sessionsCompleted = "sessionsCompleted"
        static let dailyGoal = "dailyGoal"
        static let todayTotal = "todayTotal"
        static let weekTotal = "weekTotal"
        static let currentStreak = "currentStreak"
        static let lastWorkoutDate = "lastWorkoutDate"
        static let sessionHistory = "sessionHistory"
        static let soundEnabled = "soundEnabled"
        static let voiceCountEnabled = "voiceCountEnabled"
        static let autoRestTimer = "autoRestTimer"
        static let restDuration = "restDuration"
        static let dailyRemindersEnabled = "dailyRemindersEnabled"
        static let reminderTime = "reminderTime"
        static let milestoneNotificationsEnabled = "milestoneNotificationsEnabled"
        static let goalNotificationsEnabled = "goalNotificationsEnabled"
        static let streakRemindersEnabled = "streakRemindersEnabled"
        static let goalAchievedToday = "goalAchievedToday"
        static let timerMode = "timerMode"
        static let counterTimerMinutes = "counterTimerMinutes"
        static let counterTimerSeconds = "counterTimerSeconds"
    }
    
    init() {
        loadData()
        setupAchievements()
        checkStreaks()
        checkDailyReset()
    }
    
    // MARK: - Notification Methods
    func requestNotificationPermission() {
        notificationManager.requestPermission { granted in
            print("Notification permission: \(granted)")
        }
    }
    
    func scheduleDailyReminders() {
        if dailyRemindersEnabled {
            notificationManager.scheduleDailyReminder(at: reminderTime)
        }
    }
    
    func cancelDailyReminders() {
        notificationManager.cancelDailyReminders()
    }
    
    func sendTestNotification() {
        notificationManager.sendTestNotification()
    }
    
    // MARK: - Public Methods
    func increment() {
        currentCount += 1
        totalPushUps += 1
        todayTotal += 1
        weekTotal += 1
        repTimes.append(Date())
        
        // Start stopwatch if in stopwatch mode and not running
        if timerMode == .stopwatch && !isTimerRunning {
            startStopwatch()
        }
        
        // Check for new personal best
        if currentCount > personalBest {
            personalBest = currentCount
            hapticManager.success()
            if soundEnabled {
                soundManager.playSuccess()
            }
        } else {
            hapticManager.light()
            if soundEnabled {
                soundManager.playClick()
            }
        }
        
        // Voice count
        if voiceCountEnabled && currentCount % 5 == 0 {
            soundManager.speak("\(currentCount)")
        }
        
        // Milestone notifications
        if milestoneNotificationsEnabled && isMilestone(currentCount) {
            notificationManager.sendMilestoneNotification(count: currentCount)
        }
        
        // Goal achievement notification
        if goalNotificationsEnabled && !goalAchievedToday && todayTotal >= dailyGoal {
            goalAchievedToday = true
            notificationManager.sendGoalAchievedNotification(goal: dailyGoal)
        }
        
        // Start rest timer if enabled
        if autoRestTimer {
            startRestTimer()
        }
        
        updateAchievements()
        saveData()
    }
    
    func decrement() {
        guard currentCount > 0 else { return }
        currentCount -= 1
        totalPushUps = max(0, totalPushUps - 1)
        todayTotal = max(0, todayTotal - 1)
        weekTotal = max(0, weekTotal - 1)
        if !repTimes.isEmpty {
            repTimes.removeLast()
        }
        hapticManager.light()
        saveData()
    }
    
    func quickAdd(_ amount: Int) {
        for _ in 0..<amount {
            increment()
        }
    }
    
    func resetSession() {
        guard currentCount > 0 else { return }
        
        // Save session to history
        let session = WorkoutSession(
            id: UUID(),
            count: currentCount,
            date: Date(),
            duration: timerMode == .stopwatch ? sessionTime : counterTimerElapsed
        )
        sessionHistory.insert(session, at: 0)
        
        sessionsCompleted += 1
        currentCount = 0
        sessionTime = 0
        counterTimerElapsed = 0
        repTimes.removeAll()
        
        // Stop all timers
        stopStopwatch()
        stopCounterTimer()
        stopRestTimer()
        
        // Update last workout date for streak tracking
        lastWorkoutDate = Date()
        storage.set(lastWorkoutDate, forKey: StorageKey.lastWorkoutDate)
        
        hapticManager.medium()
        if soundEnabled {
            soundManager.playComplete()
        }
        saveData()
    }
    
    func deleteSession(at offsets: IndexSet) {
        sessionHistory.remove(atOffsets: offsets)
        saveData()
    }
    
    func resetAll() {
        hapticManager.heavy()
        currentCount = 0
        personalBest = 0
        totalPushUps = 0
        sessionsCompleted = 0
        todayTotal = 0
        weekTotal = 0
        currentStreak = 0
        sessionHistory.removeAll()
        sessionTime = 0
        counterTimerElapsed = 0
        repTimes.removeAll()
        goalAchievedToday = false
        lastWorkoutDate = nil
        
        // Stop all timers
        stopStopwatch()
        stopCounterTimer()
        stopRestTimer()
        
        saveData()
    }
    
    func toggleStopwatch() {
        if isTimerRunning {
            stopStopwatch()
        } else {
            startStopwatch()
        }
    }
    
    func toggleCounterTimer() {
        if isCounterTimerRunning {
            stopCounterTimer()
        } else {
            startCounterTimer()
        }
    }
    
    func resetCounterTimer() {
        counterTimerElapsed = 0
        isCounterTimerRunning = false
        stopCounterTimer()
    }
    
    func increaseCounterTimer(minutes: Int = 0, seconds: Int = 0) {
        if minutes > 0 {
            counterTimerMinutes = min(counterTimerMinutes + minutes, 59)
        }
        if seconds > 0 {
            let newSeconds = counterTimerSeconds + seconds
            if newSeconds >= 60 {
                counterTimerMinutes = min(counterTimerMinutes + 1, 59)
                counterTimerSeconds = newSeconds - 60
            } else {
                counterTimerSeconds = newSeconds
            }
        }
        saveData()
    }
    
    func decreaseCounterTimer(minutes: Int = 0, seconds: Int = 0) {
        if minutes > 0 {
            counterTimerMinutes = max(counterTimerMinutes - minutes, 0)
        }
        if seconds > 0 {
            if counterTimerSeconds >= seconds {
                counterTimerSeconds -= seconds
            } else if counterTimerMinutes > 0 {
                counterTimerMinutes -= 1
                counterTimerSeconds = 60 + counterTimerSeconds - seconds
            } else {
                counterTimerSeconds = max(counterTimerSeconds - seconds, 0)
            }
        }
        saveData()
    }
    
    func clearNewAchievement() {
        hasNewAchievement = false
    }
    
    func exportHistory() {
        // Simple export to console for now
        print("=== Workout History Export ===")
        for session in sessionHistory {
            print("\(session.date): \(session.count) push-ups in \(session.formattedDuration)")
        }
        print("=== End Export ===")
        
        // Show a simple alert using haptic feedback
        hapticManager.success()
    }
    
    // MARK: - Private Methods
    private func isMilestone(_ count: Int) -> Bool {
        let milestones = [10, 25, 50, 75, 100, 150, 200, 250, 300, 500, 1000]
        return milestones.contains(count)
    }
    
    private func checkDailyReset() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastDate = storage.object(forKey: StorageKey.lastWorkoutDate) as? Date {
            let lastWorkout = calendar.startOfDay(for: lastDate)
            
            if !calendar.isDate(today, inSameDayAs: lastWorkout) {
                // Reset daily stats
                todayTotal = 0
                goalAchievedToday = false
                
                // Check streak
                let daysDiff = calendar.dateComponents([.day], from: lastWorkout, to: today).day ?? 0
                if daysDiff == 1 {
                    currentStreak += 1
                } else if daysDiff > 1 {
                    currentStreak = 0
                }
                
                // Send streak reminder if enabled
                if streakRemindersEnabled && currentStreak > 0 {
                    notificationManager.sendStreakReminderNotification(streak: currentStreak)
                }
            }
        } else {
            // First time using the app
            todayTotal = 0
            goalAchievedToday = false
            currentStreak = 0
        }
    }
    
    // MARK: - Stopwatch Timer Methods
    private func startStopwatch() {
        guard !isTimerRunning else { return }
        isTimerRunning = true
        sessionStartTime = Date()
        
        stopwatchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.sessionTime += 1
            }
        }
    }
    
    private func stopStopwatch() {
        stopwatchTimer?.invalidate()
        stopwatchTimer = nil
        isTimerRunning = false
    }
    
    // MARK: - Counter Timer Methods
    private func startCounterTimer() {
        guard !isCounterTimerRunning else { return }
        isCounterTimerRunning = true
        counterTimerStartTime = Date()
        
        counterTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.counterTimerElapsed += 1
                
                // Check if timer has finished
                let totalDuration = self.counterTimerTotalSeconds
                if self.counterTimerElapsed >= TimeInterval(totalDuration) && totalDuration > 0 {
                    self.counterTimerFinished()
                }
            }
        }
    }
    
    private func stopCounterTimer() {
        counterTimer?.invalidate()
        counterTimer = nil
        isCounterTimerRunning = false
    }
    
    private func counterTimerFinished() {
        stopCounterTimer()
        hapticManager.heavy()
        
        if soundEnabled {
            soundManager.playComplete()
        }
        
        notificationManager.sendCounterTimerFinishedNotification()
        
        // Automatically start rest timer if enabled
        if autoRestTimer {
            startRestTimer()
        }
    }
    
    // MARK: - Rest Timer Methods
    private func startRestTimer() {
        stopRestTimer()
        isRestTimerActive = true
        restTime = TimeInterval(restDuration)
        
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if self.restTime > 0 {
                    self.restTime -= 1
                } else {
                    self.stopRestTimer()
                    if self.soundEnabled {
                        self.soundManager.playBeep()
                    }
                    self.hapticManager.medium()
                }
            }
        }
    }
    
    private func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        isRestTimerActive = false
        restTime = 0
    }
    
    private func checkStreaks() {
        guard let lastDate = storage.object(forKey: StorageKey.lastWorkoutDate) as? Date else {
            currentStreak = 0
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastWorkout = calendar.startOfDay(for: lastDate)
        let daysDiff = calendar.dateComponents([.day], from: lastWorkout, to: today).day ?? 0
        
        if daysDiff == 1 {
            currentStreak += 1
        } else if daysDiff > 1 {
            currentStreak = 0
        }
    }
    
    private func setupAchievements() {
        achievements = [

            // 🟢 Beginner
            Achievement(
                title: "First Step",
                description: "Complete 1 push-up",
                icon: "figure.walk",
                targetProgress: 1,
                currentProgress: totalPushUps
            ),

            Achievement(
                title: "Getting Started",
                description: "Complete 10 push-ups",
                icon: "star.fill",
                targetProgress: 10,
                currentProgress: totalPushUps
            ),

            Achievement(
                title: "Warm Up",
                description: "Complete 25 push-ups",
                icon: "bolt.fill",
                targetProgress: 25,
                currentProgress: totalPushUps
            ),

            // 🟡 Session-based
            Achievement(
                title: "Half Century",
                description: "Complete 50 push-ups in one session",
                icon: "50.circle.fill",
                targetProgress: 50,
                currentProgress: personalBest
            ),

            Achievement(
                title: "Iron Arms",
                description: "Complete 75 push-ups in one session",
                icon: "hammer.fill",
                targetProgress: 75,
                currentProgress: personalBest
            ),

            Achievement(
                title: "Century Club",
                description: "Complete 100 push-ups in one session",
                icon: "100.circle.fill",
                targetProgress: 100,
                currentProgress: personalBest
            ),

            // 🔥 Streaks
            Achievement(
                title: "Consistent",
                description: "Complete a 7-day streak",
                icon: "flame.fill",
                targetProgress: 7,
                currentProgress: currentStreak
            ),

            Achievement(
                title: "On Fire",
                description: "Complete a 14-day streak",
                icon: "flame.circle.fill",
                targetProgress: 14,
                currentProgress: currentStreak
            ),

            Achievement(
                title: "Unbreakable",
                description: "Complete a 30-day streak",
                icon: "shield.fill",
                targetProgress: 30,
                currentProgress: currentStreak
            ),

            // 📅 Sessions
            Achievement(
                title: "Dedicated",
                description: "Complete 30 sessions",
                icon: "calendar.badge.checkmark",
                targetProgress: 30,
                currentProgress: sessionsCompleted
            ),

            Achievement(
                title: "Habit Builder",
                description: "Complete 75 sessions",
                icon: "calendar.circle.fill",
                targetProgress: 75,
                currentProgress: sessionsCompleted
            ),

            Achievement(
                title: "Daily Grinder",
                description: "Complete 150 sessions",
                icon: "clock.fill",
                targetProgress: 150,
                currentProgress: sessionsCompleted
            ),

            // 🏆 Lifetime totals
            Achievement(
                title: "Thousand Club",
                description: "Complete 1,000 total push-ups",
                icon: "trophy.fill",
                targetProgress: 1000,
                currentProgress: totalPushUps
            ),

            Achievement(
                title: "Iron Chest",
                description: "Complete 5,000 total push-ups",
                icon: "medal.fill",
                targetProgress: 5000,
                currentProgress: totalPushUps
            ),

            Achievement(
                title: "Push-Up Legend",
                description: "Complete 10,000 total push-ups",
                icon: "crown.fill",
                targetProgress: 10_000,
                currentProgress: totalPushUps
            )
        ]
    }

    
    private func updateAchievements() {
        let previousAchievements = achievements.filter { $0.isUnlocked }.count
        setupAchievements()
        let newAchievements = achievements.filter { $0.isUnlocked }.count
        
        if newAchievements > previousAchievements {
            hasNewAchievement = true
            hapticManager.success()
            if soundEnabled {
                soundManager.playAchievement()
            }
            
            // Send achievement notification
            if let newAchievement = achievements.first(where: { $0.isUnlocked && $0.currentProgress == $0.targetProgress }) {
                notificationManager.sendAchievementNotification(title: newAchievement.title)
            }
        }
    }
    
    private func saveData() {
        storage.set(personalBest, forKey: StorageKey.personalBest)
        storage.set(totalPushUps, forKey: StorageKey.totalPushUps)
        storage.set(sessionsCompleted, forKey: StorageKey.sessionsCompleted)
        storage.set(dailyGoal, forKey: StorageKey.dailyGoal)
        storage.set(todayTotal, forKey: StorageKey.todayTotal)
        storage.set(weekTotal, forKey: StorageKey.weekTotal)
        storage.set(currentStreak, forKey: StorageKey.currentStreak)
        storage.set(Date(), forKey: StorageKey.lastWorkoutDate)
        storage.set(soundEnabled, forKey: StorageKey.soundEnabled)
        storage.set(voiceCountEnabled, forKey: StorageKey.voiceCountEnabled)
        storage.set(autoRestTimer, forKey: StorageKey.autoRestTimer)
        storage.set(restDuration, forKey: StorageKey.restDuration)
        storage.set(dailyRemindersEnabled, forKey: StorageKey.dailyRemindersEnabled)
        storage.set(reminderTime, forKey: StorageKey.reminderTime)
        storage.set(milestoneNotificationsEnabled, forKey: StorageKey.milestoneNotificationsEnabled)
        storage.set(goalNotificationsEnabled, forKey: StorageKey.goalNotificationsEnabled)
        storage.set(streakRemindersEnabled, forKey: StorageKey.streakRemindersEnabled)
        storage.set(goalAchievedToday, forKey: StorageKey.goalAchievedToday)
        
        // Save timer mode
        switch timerMode {
        case .stopwatch:
            storage.set("stopwatch", forKey: StorageKey.timerMode)
        case .counter:
            storage.set("counter", forKey: StorageKey.timerMode)
        }
        
        storage.set(counterTimerMinutes, forKey: StorageKey.counterTimerMinutes)
        storage.set(counterTimerSeconds, forKey: StorageKey.counterTimerSeconds)
        
        // Save session history
        if let encoded = try? JSONEncoder().encode(sessionHistory) {
            storage.set(encoded, forKey: StorageKey.sessionHistory)
        }
    }
    
    private func loadData() {
        personalBest = storage.integer(forKey: StorageKey.personalBest)
        totalPushUps = storage.integer(forKey: StorageKey.totalPushUps)
        sessionsCompleted = storage.integer(forKey: StorageKey.sessionsCompleted)
        dailyGoal = storage.integer(forKey: StorageKey.dailyGoal) == 0 ? 50 : storage.integer(forKey: StorageKey.dailyGoal)
        todayTotal = storage.integer(forKey: StorageKey.todayTotal)
        weekTotal = storage.integer(forKey: StorageKey.weekTotal)
        currentStreak = storage.integer(forKey: StorageKey.currentStreak)
        soundEnabled = storage.object(forKey: StorageKey.soundEnabled) as? Bool ?? true
        voiceCountEnabled = storage.object(forKey: StorageKey.voiceCountEnabled) as? Bool ?? false
        autoRestTimer = storage.object(forKey: StorageKey.autoRestTimer) as? Bool ?? false
        restDuration = storage.integer(forKey: StorageKey.restDuration) == 0 ? 60 : storage.integer(forKey: StorageKey.restDuration)
        dailyRemindersEnabled = storage.object(forKey: StorageKey.dailyRemindersEnabled) as? Bool ?? false
        milestoneNotificationsEnabled = storage.object(forKey: StorageKey.milestoneNotificationsEnabled) as? Bool ?? true
        goalNotificationsEnabled = storage.object(forKey: StorageKey.goalNotificationsEnabled) as? Bool ?? true
        streakRemindersEnabled = storage.object(forKey: StorageKey.streakRemindersEnabled) as? Bool ?? true
        goalAchievedToday = storage.object(forKey: StorageKey.goalAchievedToday) as? Bool ?? false
        
        if let savedTime = storage.object(forKey: StorageKey.reminderTime) as? Date {
            reminderTime = savedTime
        }
        
        // Load timer mode
        if let savedMode = storage.string(forKey: StorageKey.timerMode) {
            switch savedMode {
            case "counter":
                timerMode = .counter
            default:
                timerMode = .stopwatch
            }
        }
        
        counterTimerMinutes = storage.integer(forKey: StorageKey.counterTimerMinutes)
        counterTimerSeconds = storage.integer(forKey: StorageKey.counterTimerSeconds)
        
        // Load session history
        if let data = storage.data(forKey: StorageKey.sessionHistory),
           let decoded = try? JSONDecoder().decode([WorkoutSession].self, from: data) {
            sessionHistory = decoded.sorted { $0.date > $1.date } // Sort by most recent first
        }
        
        lastWorkoutDate = storage.object(forKey: StorageKey.lastWorkoutDate) as? Date
    }
}

// MARK: - Haptic Feedback Manager
class HapticFeedbackManager {
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    
    init() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notification.prepare()
    }
    
    func light() {
        lightImpact.impactOccurred()
        lightImpact.prepare()
    }
    
    func medium() {
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
    }
    
    func heavy() {
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
    }
    
    func success() {
        notification.notificationOccurred(.success)
        notification.prepare()
    }
}

// MARK: - Sound Manager
class SoundManager {
    private let synthesizer = AVSpeechSynthesizer()
    
    func playClick() {
        AudioServicesPlaySystemSound(1104)
    }
    
    func playSuccess() {
        AudioServicesPlaySystemSound(1054)
    }
    
    func playComplete() {
        AudioServicesPlaySystemSound(1016)
    }
    
    func playBeep() {
        AudioServicesPlaySystemSound(1052)
    }
    
    func playAchievement() {
        AudioServicesPlaySystemSound(1057)
    }
    
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainTabView()
                .environmentObject(PushUpViewModel())
                .previewDevice("iPhone 15 Pro")
                .previewDisplayName("iPhone")
            
            MainTabView()
                .environmentObject(PushUpViewModel())
                .previewDevice("iPad Pro (12.9-inch) (6th generation)")
                .previewDisplayName("iPad Pro")
        }
    }
}
