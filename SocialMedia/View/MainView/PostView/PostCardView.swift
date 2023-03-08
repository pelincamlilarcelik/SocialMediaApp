//
//  PostCardView.swift
//  SocialMedia
//
//  Created by Onur Celik on 7.03.2023.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage


struct PostCardView: View {
    var post: Post
    // Callbacks
    var onUpdate: (Post)->()
    var onDelete: ()->()
    // View properties
    @AppStorage("user_UID") private var userUID: String = ""
    @State private var docListener: ListenerRegistration?
    var body: some View {
        HStack(alignment:.top,spacing: 12){
            WebImage(url: post.userProfileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width:35,height: 35)
                .clipShape(Circle())
            VStack(alignment: .leading,spacing: 6) {
                Text(post.username)
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(post.publishedDate.formatted(date: .numeric, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(post.text)
                    .textSelection(.enabled)
                    .padding(.vertical,8)
                // Post image if any
                if let postImageURL = post.imageURL{
                    GeometryReader{
                        let size = $0.size
                        WebImage(url: postImageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width:size.width,height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10,style: .continuous))
                        
                    }
                    .frame(height: 200)
                }
                PostInteraction()
            }
        }
        .hAlign(.leading)
        .overlay(alignment:.topTrailing,content: {
            // Displaying delete button
            if post.userID == userUID{
                Menu {
                    Button("Delete Post", role: .destructive, action: deletePost)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .rotationEffect(Angle(degrees: -90))
                        .foregroundColor(.black)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .offset(x:8)

            }
        })
        .onAppear{
            // Adding only once
            if docListener == nil{
                guard let postID = post.id else {return}
                docListener = Firestore.firestore().collection("Posts").document(postID).addSnapshotListener({ snapshot, error in
                    if let snapshot{
                        if snapshot.exists{
                            // Document updated
                            // Fetching updated document
                            if let updatedPost = try? snapshot.data(as: Post.self){
                                onUpdate(updatedPost)
                            }
                        }else{
                            // Document deleted
                            onDelete()
                        }
                    }
                })
            }
        }
        .onDisappear{
            if let docListener{
                docListener.remove()
                self.docListener = nil
            }
        }
    }
    // like/dislike interaction
    @ViewBuilder
    func PostInteraction()->some View{
        HStack(spacing: 6) {
            Button (action:likePost)  {
                Image(systemName: post.likedIDs.contains(userUID) ? "hand.thumbsup.fill" : "hand.thumbsup")
            }
            Text("\(post.likedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action:dislikePost){
                Image(systemName: post.dislikedIDs.contains(userUID) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }
            .padding(.leading,25)
            Text("\(post.dislikedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)

        }
        .foregroundColor(.black)
        .padding(.vertical,8)
    }
    func likePost(){
        Task{
            guard let postID = post.id else {return}
            
            if post.likedIDs.contains(userUID){
               // Removing userid from the array
                 try await Firestore.firestore().collection("Posts").document(postID)
                    .updateData(["likedIDs": FieldValue.arrayRemove([userUID])])
                
            }else{
                // Adding user id to liked array and removing our id from disliked array(if added)
                 try await Firestore.firestore().collection("Posts").document(postID)
                    .updateData(["likedIDs": FieldValue.arrayUnion([userUID]),
                                 "dislikedIDs": FieldValue.arrayRemove([userUID])
                                ])
            }
        }
    }
    // dislike post
    func dislikePost(){
        Task{
            guard let postID = post.id else {return}
            
            if post.dislikedIDs.contains(userUID){
               // Removing userid from the array
                 try await Firestore.firestore().collection("Posts").document(postID)
                    .updateData(["dislikedIDs": FieldValue.arrayRemove([userUID])])
                
            }else{
                // Adding user id to liked array and removing our id from disliked array(if added)
                 try await Firestore.firestore().collection("Posts").document(postID)
                    .updateData(["dislikedIDs": FieldValue.arrayUnion([userUID]),
                                 "likedIDs": FieldValue.arrayRemove([userUID])
                                ])
            }
        }
    }
    
    func deletePost(){
        Task{
            // Step 1: Delete image from storage(if present)
            do{
                if post.imageReferenceID != ""{
                    try await Storage.storage().reference().child("Post_Images").child(post.imageReferenceID).delete()
                }
                // Step 2: Delete firestore document
                guard let postID = post.id else {return}
                try await Firestore.firestore().collection("Posts").document(postID).delete()
            }catch{
                print(error.localizedDescription)
            }
        }
    }
}


