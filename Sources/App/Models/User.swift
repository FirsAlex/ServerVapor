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
    
    

    init() { }

    init(id: UUID? = nil, title: String, telephone: String) {
        self.id = id
        self.name = name
        self.telephone = telephone
    }
}
