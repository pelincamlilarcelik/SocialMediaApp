//
//  LoginView.swift
//  SocialMedia
//
//  Created by Onur Celik on 5.03.2023.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
struct LoginView: View {
    @State var emailID: String = ""
    @State var password: String = ""
    @State var createAccount: Bool = false
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNamedStore: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    var body: some View {
        VStack(spacing: 10) {
            Text("Lets Sign You In")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            Text("Wellcome Back,\nYou have been missed")
                .font(.title3)
                .hAlign(.leading)
            VStack(spacing: 12) {
                TextField("Email", text: $emailID)
                    .textContentType(.emailAddress)
                    .border(1, .gray)
                    .padding(.top,25)
                
                TextField("Password", text: $password)
                    .textContentType(.emailAddress)
                    .border(1, .gray)
                Button("Reset Password", action: resetPassword)
                    .font(.callout)
                    .tint(.black)
                    .fontWeight(.medium)
                    .hAlign(.trailing)
                Button {
                   loginUser()
                } label: {
                    Text("Sign In")
                        .foregroundColor(.white)
                        .hAlign(.center)
                        .fillView(.black)
                }
                .padding(.top,10)

            }
            HStack{
                Text("Don't have an account?")
                    .foregroundColor(.gray)
                Button("Register Now") {
                    createAccount.toggle()
                }
                .foregroundColor(.black)
                .bold()
                
                
            }
            .font(.callout)
            .vAlign(.bottom)
        }
        .vAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        // MARK: Register  View VIA Sheets
        .fullScreenCover(isPresented: $createAccount) {
            RegisterView()
        }
        // MARK: Displaying alert
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    func loginUser(){
        closeKeyboard()
        isLoading = true
        Task{
            do{
                try await Auth.auth().signIn(withEmail: emailID, password: password)
                isLoading = false
                print("User Found")
                try await fetchUser()
            }catch{
                await setError(error)
            }
        }
    }
    func fetchUser()async throws{
        guard let userID = Auth.auth().currentUser?.uid else {return}
        let user = try await Firestore.firestore().collection("Users").document(userID).getDocument(as: User.self)
        // MARK: UI Updated must be run on main thread
        await MainActor.run(body: {
            userUID = userID
            userNamedStore = user.username
            profileURL = user.userProfileURL
            logStatus = true
        })
    }
    func resetPassword(){
        Task{
            do{
                try await Auth.auth().sendPasswordReset(withEmail: emailID)
                print("Link Sent")
            }catch{
                await setError(error)
            }
        }
    }
    func setError(_ error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}



struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}



