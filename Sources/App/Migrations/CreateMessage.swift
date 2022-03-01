import Fluent

struct CreateMessage: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("messages")
            .id()
            .field("text", .string, .required)
            .field("delivered", .bool, .required, .custom("DEFAULT false"))
            .field("from_user_id", .uuid, .required, .references("users", "id"))
            .field("to_user_id", .uuid, .required, .references("users", "id"))
            .field("created_at", .string, .required)
            .field("updated_at", .string)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("messages").delete()
    }
}
