import Fluent
import Vapor

struct CreateContactRequestBody: Content {
    let name: String
    let telephone: String
    
    func makeContact(_ userID: User.IDValue ) -> Contact {
        return Contact(name: name, telephone: telephone, userID: userID)
    }
}

struct ContactController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let todos = routes.grouped("contacts")
            todos.get(use: selectAllContacts)
            todos.delete(use: deleteAllContacts)
        
            todos.group(":contactID") { todo in
                todo.delete(use: deleteContactByID)
                todo.get(use: selectContactByID)
            }
            
            todos.group("by_user", ":userID") { todo in
                todo.post(use: insertContact)
            }
    }

    func insertContact(req: Request) throws -> EventLoopFuture<Contact> {
        guard let userIDString = req.parameters.get("userID"),
            let userID = UUID(userIDString) else {
                throw Abort(.badRequest, reason: "Invalid parameter `userID`")
        }
            
        let createContactRequestBody = try req.content.decode(CreateContactRequestBody.self)
        let contact = createContactRequestBody.makeContact(userID)
        return contact.save(on: req.db).map { contact }
    }
    
    func selectAllContacts(req: Request) throws -> EventLoopFuture<[Contact]> {
        return Contact.query(on: req.db).all()
    }

    func selectContactByID(req: Request) throws -> EventLoopFuture<Contact> {
        guard let contactIDString = req.parameters.get("contactID"),
            let contactID = UUID(contactIDString) else {
                throw Abort(.badRequest, reason: "Invalid parameter `contactID`")
        }
        return Contact.find(contactID, on: req.db)
            .unwrap(or: Abort(.notFound)) // return 404 if the todo hasn't been found
    }
    
    func deleteAllContacts(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Contact.query(on: req.db)
            .delete()
            .transform(to: .ok) // transform to response status code 200
    }

    func deleteContactByID(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Contact.find(req.parameters.get("contactID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
    
}
