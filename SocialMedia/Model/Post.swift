//
//  Post.swift
//  SocialMedia
//
//  Created by Onur Celik on 7.03.2023.
//

import SwiftUI
import FirebaseFirestoreSwift

struct Post: Identifiable,Codable,Equatable,Hashable{
    @DocumentID var id: String?
    var text: String
    var imageURL: URL?
    var imageReferenceID: String = ""
    var publishedDate: Date = Date()
    var likedIDs: [String] = []
    var dislikedIDs: [String] = []
    
    var username: String
    var userID: String
    var userProfileURL: URL
    
    enum CodingKeys: CodingKey{
        case id
        case text
        case imageURL
        case imageReferenceID
        case publishedDate
        case likedIDs
        case dislikedIDs
        case username
        case userID
        case userProfileURL
    }
    
}
