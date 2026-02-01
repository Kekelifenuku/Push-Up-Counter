//
//  Push_Up_CounterApp.swift
//  Push Up Counter
//
//  Created by Fenuku kekeli on 2/1/26.
//

import SwiftUI

@main
struct Push_Up_CounterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = PushUpViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(viewModel)
                .preferredColorScheme(.dark)
                .onAppear {
                    viewModel.requestNotificationPermission()
                }
        }
    }
}
