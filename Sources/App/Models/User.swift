import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"
    
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
    
    @Children(for: \.$user)
    var contacts: [Contact]

    @Children(for: \.$fromUser)
    var fromUsers: [Message]
    
    @Children(for: \.$toUser)
    var toUsers: [Message]
    
    init() { }

    init(id: UUID? = nil, name: String, telephone: String) {
        self.id = id
        self.name = name
        self.telephone = telephone
    }
}
