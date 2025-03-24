import Testing
@testable import Posts

final class ApiClientTests {
    
    var sut: ApiClient!
    
    init() {
        sut = .mockup()
    }
    
    @Test
    func testRequestPosts_withDistinctiveValues_validatesEachPost() async {
        // When
        do {
            let posts = try await sut.requestPosts(FetchPostsRequest())
            
            // Then
            #expect(posts.count == 3,                   "Expected 3 posts but got \(posts.count)")
            #expect(posts[0].id == 1,                   "First post ID does not match")
            #expect(posts[0].userID == 1,               "First post user ID does not match")
            #expect(posts[0].title == "Title 1",        "First post title does not match")
            // Add more assertions as needed
        } catch {
            #expect(Bool(false), "Error fetching posts: \(error.localizedDescription)")
        }
    }
    
    @Test
    func testAddingPost_withDistinctiveValues_validatesAddedPost() async {
        // Given
        let newPostRequest = AddPostRequest(title: "New Post", body: "Body of new post", userID: 4)
        
        // When
        do {
            let addedPost = try await sut.addPost(newPostRequest)
            
            // Then
            #expect(addedPost.userID == 4,          "Added post ID should match")
            #expect(addedPost.title == "New Post",  "Added post title should match")
            // Add more assertions as needed
        } catch {
            #expect(Bool(false), "Error fetching posts: \(error.localizedDescription)")
        }
    }
}

extension ApiClient {
    static func mockup() -> ApiClient {
        var data: [Post] = Post.testing
        
        // Define mock data and behavior for requesting posts
        let requestingPosts: @Sendable (FetchPostsRequest) async throws -> [Post] = { _ in
            return Post.testing
        }
        
        // Define mock data and behavior for adding post
        let addingPost: @Sendable (AddPostRequest) async throws -> Post = { request in
            let post = Post(id: 0, body: request.body, title: request.title, userID: request.userID)
            var data = data
            data.append(post)
            return post
        }
        
        // Define mock data and behavior for updating post
        let updatePost: @Sendable (UpdatePostRequest) async throws -> Post = { [data] request in
            var posts = data
            guard let i = posts.firstIndex(where: { $0.id == request.id }) else {
                throw ApiClientError.undefined(message: "No post to update found")
            }
            
            let post = Post(id: i, body: request.body, title: request.title, userID: request.userID)
            posts[i] = post
            return post
        }
        
        // Define mock data and behavior for patching post
        let patchPost: @Sendable (PatchPostRequest) async throws -> Post = { [data] request in
            var posts = data
            guard let index = posts.firstIndex(where: { $0.id == request.id }) else {
                    throw ApiClientError.undefined(message: "No post found to patch")
                }
                
                let existingPost = posts[index]
                
                // Apply partial updates from the request
                let updatedPost = Post(
                    id: existingPost.id,
                    body: request.body ?? existingPost.body,
                    title: request.title ?? existingPost.title,
                    userID: existingPost.userID
                )
                
                // Update the post in the array
                posts[index] = updatedPost
                
                return updatedPost
        }
        
        // Create mock ApiClient with the defined behaviors
        return ApiClient(
            requestPosts: requestingPosts,
            addPost: addingPost,
            updatePost: updatePost,
            patchPost: patchPost
        )
    }
}

extension Post {
    static let testing: [Self] = [
        .init(id: 1, body: "Body 1", title: "Title 1", userID: 1),
        .init(id: 2, body: "Body 2", title: "Title 2", userID: 2),
        .init(id: 3, body: "Body 3", title: "Title 3", userID: 3)
    ]
}
