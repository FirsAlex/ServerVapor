import Fluent
import FluentSQLiteDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    app.migrations.add(CreateUser())
    app.migrations.add(CreateContact())
    app.migrations.add(CreateMessage())
    try app.autoMigrate().wait()
    // register routes
    try routes(app)
    app.http.server.configuration.hostname = "192.168.1.58"
}
