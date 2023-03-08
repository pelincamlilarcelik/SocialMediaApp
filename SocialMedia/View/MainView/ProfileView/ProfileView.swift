//
//  ProfileView.swift
//  SocialMedia
//
//  Created by Onur Celik on 7.03.2023.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
struct ProfileView: View {
    @State private var myProfile: User?
    @AppStorage("log_status") var logStatus: Bool = false
    // Error Message
    @State var errorMessage: String = ""
    @State var showError: Bool = false
    @State var isLoading: Bool = false
    var body: some View {
        NavigationStack{
            VStack{
                if let myProfile{
                    ReusableProfileContent(user: myProfile)
                        .refreshable {
                            self.myProfile = nil
                            await fetchUserData()
                        }
                }else{
                    ProgressView()
                }
            }
            .refreshable {
                // Refresh user data
                myProfile = nil
                await fetchUserData()
                
            }
            .navigationTitle("My Profile")
            .toolbar {
                ToolbarItem(placement:.navigationBarTrailing) {
                    Menu {
                      // Two actions
                        // 1 Logout
                        // 2 Delete account
                        Button("Logout",action: logOutUser)
                        
                        Button("Delete Account",role: .destructive,action: deleteAccount)
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.init(degrees: 90))
                            .tint(.black)
                            .scaleEffect(0.8)
                    }

                }
            }
            
        }
        .overlay {
            LoadingView(show: $isLoading)
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
        .task {
            // This modifier is like onAppear
            // So fetching for the first time only
            if myProfile != nil {return}
            await fetchUserData()
        }
    }
    func fetchUserData()async {
        guard let userUID = Auth.auth().currentUser?.uid else {return}
        guard let user = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self) else {return}
        await MainActor.run(body: {
            myProfile = user
        })
    }
    func logOutUser(){
        try? Auth.auth().signOut()
        logStatus = false
    }
    // Deleting user entire account
    func deleteAccount(){
        isLoading = true
        Task{
            do{
                guard let userUID = Auth.auth().currentUser?.uid else {return}
                // Step 1: Deleting profile image from storage
                let reference = Storage.storage().reference().child("Profile_Images").child(userUID)
                try await reference.delete()
                // Step 2: Deleting Firestore User Document
                try await Firestore.firestore().collection("Users").document(userUID).delete()
                // Step 3: Deleting Auth account and log status to false
                try await Auth.auth().currentUser?.delete()
                logStatus = false
            }catch{
                await setError(error)
            }
            
            
        }
    }
    func setError(_ error: Error)async{
        await MainActor.run(body: {
            isLoading = false
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
