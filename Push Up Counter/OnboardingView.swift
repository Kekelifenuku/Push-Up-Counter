//
//  OnboardingView.swift
//  Push Up Counter
//
//  Created by Fenuku kekeli on 2/2/26.
//


import SwiftUI

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @State private var currentPage = 0
    @State private var selectedGoal: Int = 50
    @State private var selectedReminderTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var enableNotifications = true
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to\nPush Up Counter",
            description: "Your ultimate fitness companion for tracking and improving your push-up performance",
            iconName: "figure.strengthtraining.traditional",
            color: .purple
        ),
        OnboardingPage(
            title: "Track Your Progress",
            description: "Count every rep with haptic feedback, voice announcements, and real-time performance metrics",
            iconName: "chart.line.uptrend.xyaxis",
            color: .blue
        ),
        OnboardingPage(
            title: "Achieve Your Goals",
            description: "Set daily targets, maintain streaks, and unlock achievements as you build strength",
            iconName: "trophy.fill",
            color: .yellow
        ),
        OnboardingPage(
            title: "Stay Motivated",
            description: "Get daily reminders, celebrate milestones, and never miss a workout with smart notifications",
            iconName: "bell.badge.fill",
            color: .orange
        )
    ]
    
    var body: some View {
        GeometryReader { geometry in
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
                
                VStack(spacing: 0) {
                    // Skip button
                    if currentPage < pages.count {
                        HStack {
                            Spacer()
                            Button(action: {
                                completeOnboarding()
                            }) {
                                Text("Skip")
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding()
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Content
                    TabView(selection: $currentPage) {
                        // Welcome pages
                        ForEach(0..<pages.count, id: \.self) { index in
                            OnboardingPageView(page: pages[index])
                                .tag(index)
                        }
                        
                        // Goal setting page
                        GoalSettingView(selectedGoal: $selectedGoal)
                            .tag(pages.count)
                        
                        // Notification permission page
                        NotificationPermissionView(
                            enableNotifications: $enableNotifications,
                            selectedReminderTime: $selectedReminderTime
                        )
                        .tag(pages.count + 1)
                        
                        // Final page
                        FinalOnboardingView(
                            selectedGoal: selectedGoal,
                            enableNotifications: enableNotifications,
                            selectedReminderTime: selectedReminderTime,
                            completeOnboarding: completeOnboarding
                        )
                        .tag(pages.count + 2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentPage)
                    
                    // Page indicator and navigation
                    VStack(spacing: 24) {
                        // Custom page indicator
                        HStack(spacing: 8) {
                            ForEach(0..<(pages.count + 3), id: \.self) { index in
                                Circle()
                                    .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                                    .animation(.spring(response: 0.3), value: currentPage)
                            }
                        }
                        
                        // Next button
                        if currentPage < pages.count + 2 {
                            Button(action: {
                                withAnimation {
                                    currentPage += 1
                                }
                            }) {
                                Text(currentPage < pages.count ? "Next" : currentPage == pages.count + 2 ? "Get Started" : "Continue")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            colors: [.green, .cyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: .green.opacity(0.3), radius: 10, y: 5)
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func completeOnboarding() {
        // Save onboarding preferences
        UserDefaults.standard.set(selectedGoal, forKey: "dailyGoal")
        UserDefaults.standard.set(enableNotifications, forKey: "dailyRemindersEnabled")
        UserDefaults.standard.set(selectedReminderTime, forKey: "reminderTime")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Request notification permission if enabled
        if enableNotifications {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                if granted {
                    // Schedule initial reminder
                    DispatchQueue.main.async {
                        NotificationManager.shared.scheduleDailyReminder(at: selectedReminderTime)
                    }
                }
            }
        }
        
        withAnimation {
            isOnboardingComplete = true
        }
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let title: String
    let description: String
    let iconName: String
    let color: Color
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 180, height: 180)
                
                Image(systemName: page.iconName)
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(page.color)
            }
            
            VStack(spacing: 16) {
                // Title
                Text(page.title)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Description
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Goal Setting View
struct GoalSettingView: View {
    @Binding var selectedGoal: Int
    
    let goalOptions = [10, 20, 30, 50, 75, 100, 150, 200]
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 180, height: 180)
                
                Image(systemName: "target")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 16) {
                Text("Set Your Daily Goal")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("How many push-ups do you want to do each day?")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Goal selector
            VStack(spacing: 20) {
                Text("\(selectedGoal)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                
                Text("push-ups per day")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))
                
                // Goal options grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 12) {
                    ForEach(goalOptions, id: \.self) { goal in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedGoal = goal
                            }
                        }) {
                            Text("\(goal)")
                                .font(.headline)
                                .foregroundColor(selectedGoal == goal ? .white : .white.opacity(0.7))
                                .frame(width: 70, height: 70)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedGoal == goal ? Color.green : Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(selectedGoal == goal ? Color.green : Color.white.opacity(0.2), lineWidth: 2)
                                        )
                                )
                        }
                        .scaleEffect(selectedGoal == goal ? 1.1 : 1.0)
                    }
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Notification Permission View
struct NotificationPermissionView: View {
    @Binding var enableNotifications: Bool
    @Binding var selectedReminderTime: Date
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 180, height: 180)
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 16) {
                Text("Stay on Track")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Get daily reminders to help you maintain your streak and achieve your goals")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Notification settings
            VStack(spacing: 24) {
                // Enable toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Reminders")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Get notified to do your push-ups")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $enableNotifications)
                        .labelsHidden()
                        .tint(.green)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.1))
                )
                
                // Time picker (only if enabled)
                if enableNotifications {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                            Text("Reminder Time")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        DatePicker("", selection: $selectedReminderTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.1))
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Final Onboarding View
struct FinalOnboardingView: View {
    let selectedGoal: Int
    let enableNotifications: Bool
    let selectedReminderTime: Date
    let completeOnboarding: () -> Void
    
    @State private var showConfetti = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 180, height: 180)
                    .scaleEffect(showConfetti ? 1.2 : 1.0)
                    .opacity(showConfetti ? 0 : 1)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(.green)
                    .scaleEffect(showConfetti ? 1.2 : 0.8)
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                    showConfetti = true
                }
            }
            
            VStack(spacing: 16) {
                Text("You're All Set! 🎉")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Your fitness journey starts now")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Summary cards
            VStack(spacing: 16) {
                SummaryCard(
                    icon: "target",
                    title: "Daily Goal",
                    value: "\(selectedGoal) push-ups",
                    color: .green
                )
                
                if enableNotifications {
                    SummaryCard(
                        icon: "bell.fill",
                        title: "Daily Reminder",
                        value: formatTime(selectedReminderTime),
                        color: .orange
                    )
                }
                
                SummaryCard(
                    icon: "trophy.fill",
                    title: "Achievements",
                    value: "7 to unlock",
                    color: .yellow
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Get Started button
            Button(action: completeOnboarding) {
                HStack {
                    Text("Start Tracking")
                        .font(.headline)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [.green, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .green.opacity(0.3), radius: 10, y: 5)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(color.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}



// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isOnboardingComplete: .constant(false))
    }
}
