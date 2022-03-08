import Fluent
import Vapor
import AppKit

final class Message: Model, Content {
    static let schema = "messages"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "text")
    var text: String
    
    @Field(key: "delivered")
    var delivered: Bool
    
    @Parent(key: "from_user_id")
    var fromUser: User
    
    @Parent(key: "to_user_id")
    var toUser: User
    
    @Timestamp(key: "created_at", on: .create, format: .iso8601)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update, format: .iso8601)
    var updatedAt: Date?
    
    init() { }

    init(id: UUID? = nil, text: String, delivered: Bool = false, fromUserID: User.IDValue, toUserID: User.IDValue) {
        self.id = id
        self.text = text
        self.delivered = delivered
        self.$fromUser.id = fromUserID
        self.$toUser.id = toUserID
    }
}

