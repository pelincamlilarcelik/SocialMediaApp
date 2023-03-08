//
//  ReusablePostView.swift
//  SocialMedia
//
//  Created by Onur Celik on 7.03.2023.
//

import SwiftUI
import Firebase
struct ReusablePostView: View {
    var basedOnUID: Bool = false
    var uid: String = ""
    @Binding var posts: [Post]
    @State private var isFetching: Bool = false
    // Pagination
    @State private var paginationDoc: QueryDocumentSnapshot?
    var body: some View {
        ScrollView(.vertical,showsIndicators: false) {
            LazyVStack{
                if isFetching{
                    ProgressView()
                        .padding(.top,30)
                }else{
                    if posts.isEmpty{
                        // No posts found on firestore
                        Text("No Posts Found")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top,30)
                    }else{
                        // Displaying posts
                        Posts()
                    }
                }
            }
            .padding(15)
        }
        .refreshable {
            guard !basedOnUID else {return}
            isFetching = true
            posts = []
            // Resseting pagination doc nil
            paginationDoc = nil
            await fetchPosts()
            
        }
        .task {
            // Fetching for one time
            guard posts.isEmpty else {return}
            await fetchPosts()
        }
    }
    @ViewBuilder
    // Displaying fetched posts
    func Posts()->some View{
        ForEach(posts) { post in
            PostCardView(post: post) { updatedPost in
                // Updating post in array
                if let index = posts.firstIndex(where: { post in
                    post.id == updatedPost.id
                }){
                    posts[index].likedIDs = updatedPost.likedIDs
                    posts[index].dislikedIDs = updatedPost.dislikedIDs
                }
            } onDelete: {
                // removing post from array
                withAnimation(.easeInOut(duration: 0.25)) {
                    posts.removeAll{post.id == $0.id}
                }
            }
            .onAppear{
                // When the last post appears ,fetching new post if any
                if post.id == posts.last?.id && paginationDoc != nil{
                    Task{await fetchPosts()}
                }
            }

            Divider()
                .padding(.horizontal,-15)
        }
    }
    func fetchPosts()async{
        isFetching = true
        do{
            var query: Query!
            // Implementing Pagination
            if let paginationDoc{
                query = Firestore.firestore().collection("Posts")
                    .order(by: "publishedDate", descending: true)
                    .start(afterDocument: paginationDoc)
                    .limit(to: 20)
            }else{
                query = Firestore.firestore().collection("Posts")
                    .order(by: "publishedDate", descending: true)
                    .limit(to: 20)
            }
            if basedOnUID{
                query = query.whereField("userID", isEqualTo: uid)
            }
            
            
            let docs = try await query.getDocuments()
            let fetchedPosts = docs.documents.compactMap({doc -> Post? in
                try? doc.data(as: Post.self)
            })
            await MainActor.run(body: {
                self.posts.append(contentsOf: fetchedPosts)
                self.paginationDoc = docs.documents.last
                isFetching = false
            })
        }catch{
            print(error.localizedDescription)
        }
    }
}

struct ReusablePostView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
