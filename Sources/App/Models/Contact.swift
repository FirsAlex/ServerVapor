import Fluent
import Vapor

final class Contact: Model, Content {
    static let schema = "contacts"
    
    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "telephone")
    var telephone: String
    
    @Timestamp(key: "created_at", on: .create, format: .iso8601)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update, format: .iso8601)
    var updatedAt: Date?

    @Parent(key: "user_id")
    var user: User
    
    init() { }

    init(id: UUID? = nil, name: String, telephone: String, userID: User.IDValue) {
        self.id = id
        self.name = name
        self.telephone = telephone
        self.$user.id = userID
    }
}
