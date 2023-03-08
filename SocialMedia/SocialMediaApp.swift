//
//  SocialMediaApp.swift
//  SocialMedia
//
//  Created by Onur Celik on 5.03.2023.
//

import SwiftUI
import Firebase
@main
struct SocialMediaApp: App {
    init(){
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
