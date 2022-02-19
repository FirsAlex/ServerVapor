import Fluent
import Vapor

struct ContactController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let todos = routes.grouped("contacts")
            todos.get(use: index)
            todos.post(use: create)
            todos.group(":contactID") { todo in
                todo.delete(use: delete)
            }
    }


}
