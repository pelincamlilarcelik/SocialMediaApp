//
//  ContentView.swift
//  SocialMedia
//
//  Created by Onur Celik on 5.03.2023.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("log_status") var logStatus: Bool = false
    var body: some View {
        if logStatus{
            MainView()
        }else{
            LoginView()
        }
        
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
