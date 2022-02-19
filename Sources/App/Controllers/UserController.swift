import Fluent
import Vapor

struct CreateUserRequestBody: Content {
    let name: String
    let telephone: String
    
    func makeUser() -> User {
        return User(name: name, telephone: telephone)
    }
}

struct PatchUserRequestBody: Content {
        let name: String?
        let telephone: String?
}

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let todos = routes.grouped("users")
            todos.get(use: selectAllUsers)
            todos.post(use: insertUser)
            todos.delete(use: deleteAllUsers)
        
            todos.group(":userID") { todo in
                todo.delete(use: deleteUserByID)
                todo.get(use: selectUserByID)
                todo.patch(use: updateUserByID)
            }
    }

    func selectAllUsers(req: Request) throws -> EventLoopFuture<[User]> {
        return User.query(on: req.db).all()
    }

    func selectUserByID(req: Request) throws -> EventLoopFuture<User> {
        guard let userIDString = req.parameters.get("userID"),
            let userID = UUID(userIDString) else {
                throw Abort(.badRequest, reason: "Invalid parameter `userID`")
        }
        return User.find(userID, on: req.db)
            .unwrap(or: Abort(.notFound)) // return 404 if the todo hasn't been found
    }
    
    func insertUser(req: Request) throws -> EventLoopFuture<User> {
            let createTodoRequestBody = try req.content.decode(CreateTodoRequestBody.self)
            let todo = createTodoRequestBody.makeTodo()
            return todo.save(on: req.db)
                .map { todo }
    }
    
    func deleteAllUsers(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return User.query(on: req.db)
            .delete()
            .transform(to: .ok) // transform to response status code 200
    }

    func deleteUserByID(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return User.find(req.parameters.get("userID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
    
    func updateUserByID(req: Request) throws -> EventLoopFuture<HTTPStatus> {
            guard let userIDString = req.parameters.get("userID"),
                let userID = UUID(userIDString) else {
                    throw Abort(.badRequest, reason: "Invalid parameter `userID`")
            }

            let patchUserRequestBody = try req.content.decode(PatchUserRequestBody.self)
            return User.find(userID, on: req.db)
                .unwrap(or: Abort(.notFound))
                .flatMap { user in
                    if let name = patchUserRequestBody.name {
                        user.name = name
                    }
                    if let telephone = patchUserRequestBody.telephone {
                        user.telephone = telephone
                    }
                    return todo.update(on: req.db)
                        .transform(to: user)
                }
                .transform(to: .ok)
    }
}
