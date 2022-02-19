import Fluent

struct CreateContact: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("contacts")
            .id()
            .field("name", .string, .required)
            .field("telephone", .string, .required, .onCustom("UNIQUE"))
            .field("created_at", .string, .required)
            .field("user_id", .uuid, .required, .references("user", "id"))
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("contacts").delete()
    }
}