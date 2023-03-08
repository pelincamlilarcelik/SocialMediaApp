//
//  mainView.swift
//  SocialMedia
//
//  Created by Onur Celik on 7.03.2023.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        //MARK: Tabview with recent posts and profile tabs
        TabView{
            PostsView()
                .tabItem {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled")
                    Text("Post's")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Profile")
                }

        }
        .tint(.black)
    }
}

struct mainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
