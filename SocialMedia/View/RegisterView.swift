//
//  RegisterView.swift
//  SocialMedia
//
//  Created by Onur Celik on 7.03.2023.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import PhotosUI

struct RegisterView: View{
    @State var emailID: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var userBio: String = ""
    @State var userBioLink: String = ""
    @State var userProfilePicData: Data?
    @Environment(\.dismiss) var dismiss
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    
    // MARK: UserDeafaults
    
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNamedStore: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    
    var body: some View{
        VStack(spacing: 10) {
            Text("Lets Register,\nAccount")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            Text("Hello user,have a wonderful journey")
                .font(.title3)
                .hAlign(.leading)
            
            VStack(spacing: 12) {
                ZStack{
                    if let userProfilePicData, let image = UIImage(data: userProfilePicData){
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)

                    }else{
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            
                    }
                }
                .frame(width: 85,height: 85)
                .clipShape(Circle())
                .onTapGesture {
                    showImagePicker.toggle()
                }
                .padding(.top,25)
                TextField("Username", text: $userName)
                    .textContentType(.emailAddress)
                    .border(1, .gray)
                    
                
                TextField("Email", text: $emailID)
                    .textContentType(.emailAddress)
                    .border(1, .gray)
                    
                
                TextField("Password", text: $password)
                    .textContentType(.emailAddress)
                    .border(1, .gray)
                TextField("About You", text: $userBio,axis: .vertical)
                    .frame(minHeight: 100,alignment: .top)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                TextField("Bio Link (Optional)", text: $userBioLink)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                
                Button {
                    registerUser()
                } label: {
                    Text("Sign Up")
                        .foregroundColor(.white)
                        .hAlign(.center)
                        .fillView(.black)
                }
                .disableWithOpacity(userName == "" || userBio == "" || emailID == "" || password == "" || userProfilePicData == nil)
                .padding(.top,10)

            }
            HStack{
                Text("Already have an account?")
                    .foregroundColor(.gray)
                Button("Login Now") {
                    dismiss()
                }
                .foregroundColor(.black)
                .bold()
                
                
            }
            .font(.callout)
            .vAlign(.bottom)
        }
        .vAlign(.top)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        .padding(15)
        
        .alert(errorMessage, isPresented: $showError, actions: {})
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { newValue in
            // MARK: Extracting UIImage From PhotoItem
            if let newValue{
                Task{
                    do{
                        guard  let imageData = try await newValue.loadTransferable(type: Data.self) else {return}
                        // MARK: UI Must be updated on main thread
                        await MainActor.run(body: {
                            userProfilePicData = imageData
                        })
                    }catch{}
                }
            }
        }
    }
        
    func registerUser(){
        isLoading = true
        closeKeyboard()
        Task{
            do{
                // MARK: Creating firebase account
                try await Auth.auth().createUser(withEmail:emailID,password:password)
                // MARK: Uploading profile photo into firebase storage
                guard let userID = Auth.auth().currentUser?.uid else {return}
                guard let imageData = userProfilePicData else {return}
                let storageRef = Storage.storage().reference().child("Profile_Images").child(userID)
                try await storageRef.putDataAsync(imageData)
                // MARK: Downloading photo URL
                let downloadURL = try await storageRef.downloadURL()
                // MARK: Creating a user firebase object
                let user = User(username: userName, userBio: userBio, userBioLink: userBioLink, userID: userID, userEmail: emailID, userProfileURL: downloadURL)
                //MARK: Saving user doc in firebase database
                let _  = try Firestore.firestore().collection("Users").document(userID).setData(from: user,completion: { error in
                    if error == nil{
                        isLoading = false
                        print("Saved successfully")
                        userNamedStore = userName
                        self.userUID = userID
                        profileURL = downloadURL
                        logStatus = true
                        
                        
                    }
                })
            }catch{
                //try await Auth.auth().currentUser?.delete()
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

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
