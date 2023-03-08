//
//  CreateNewPost.swift
//  SocialMedia
//
//  Created by Onur Celik on 7.03.2023.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage

struct CreateNewPost: View {
    /// Callbacks
    var onPost: (Post)-> ()
    @State private var postText: String = ""
    @State private var postImageData: Data?
    /// Stored user data from UserDefaults(AppStorage)
    @AppStorage("user_profile_url") private var profileURL: URL?
    @AppStorage("user_name") private var userNamedStore: String = ""
    @AppStorage("user_UID") private var userUID: String = ""
    
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var showKeyboard: Bool
    var body: some View {
        VStack{
            HStack{
                Menu {
                    Button("Cancel", role: .destructive) {
                        dismiss()
                    }
                } label: {
                    Text("Cancel")
                        .font(.callout)
                        .foregroundColor(.black)
                }
                .hAlign(.leading)
                Button(action: createPost) {
                    Text("Post")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal,20)
                        .padding(.vertical,6)
                        .background(.black,in:Capsule())
                }
                .disableWithOpacity(postText == "")

            }
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .background {
                Rectangle()
                    .fill(.gray.opacity(0.05))
                    .ignoresSafeArea()
            }
            ScrollView(.vertical,showsIndicators: false){
                VStack(spacing:15){
                    TextField("What's happening?", text: $postText,axis: .vertical)
                        .focused($showKeyboard)
                    if let postImageData,let image = UIImage(data: postImageData){
                        GeometryReader { proxy in
                            let size = proxy.size
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width:size.width,height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 10,style: .continuous))
                            // Delete Button
                                .overlay(alignment:.topTrailing) {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)){
                                            self.postImageData = nil
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .tint(.red)
                                    }
                                    .padding(10)

                                }
                        }
                        .clipped()
                        .frame(height: 220)
                    }
                }
                .padding(15)
            }
            Divider()
            HStack{
                Button {
                    showImagePicker.toggle()
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                        
                }
                .hAlign(.leading)
                Button("Done") {
                    showKeyboard = false
                }

            }
            .foregroundColor(.black)
            .padding(.horizontal,15)
            .padding(.vertical,10)
        }
        .vAlign(.top)
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { newValue in
            if let newValue{
                Task{
                    if let rawImageData = try? await newValue.loadTransferable(type: Data.self),let image = UIImage(data: rawImageData),let compressedImageData = image.jpegData(compressionQuality: 0.5){
                        await MainActor.run(body: {
                            self.postImageData = compressedImageData
                            photoItem = nil
                        })
                    }
                }
            }
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
        .overlay {
            LoadingView(show: $isLoading)
        }
    }
    func createPost(){
        isLoading = true
        showKeyboard = false
        Task{
            do{
                guard let profileURL = profileURL else {return}
                // Step 1: Uploading image if any
                // Used to delete the post
                let imageReferenceID = "\(userUID)\(Date())"
                let storageRef = Storage.storage().reference().child("Post_Images").child(imageReferenceID)
                if let postImageData{
                    let _ = try await storageRef.putDataAsync(postImageData)
                    let downloadURL = try await storageRef.downloadURL()
                    // Create post object with image id and url
                    let post = Post(text: postText, imageURL: downloadURL,imageReferenceID: imageReferenceID,username: userNamedStore, userID: userUID, userProfileURL: profileURL)
                    try await createDocumentAtFirebase(post)
                    
                }else{
                    // Directly post text data to firebase(There is no images present)
                    let post = Post(text: postText, username: userNamedStore, userID: userUID, userProfileURL: profileURL)
                    try await createDocumentAtFirebase(post)
                }
            }catch{
                await setError(error)
            }
        }
    }
    func createDocumentAtFirebase(_ post:Post)async throws{
        // writing document to firestore
        let doc = Firestore.firestore().collection("Posts").document()
        let _ = try doc.setData(from: post) { error in
            if error == nil{
                // Post successfully stored in firestore
                isLoading = false
                var updatedPost = post
                updatedPost.id = doc.documentID
                onPost(updatedPost)
                dismiss()
                
                
            }
        }
    }
    // Displaying error as  alert
    func setError(_ error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            
        })
    }
}

struct CreateNewPost_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewPost{_ in
            
        }
    }
}
