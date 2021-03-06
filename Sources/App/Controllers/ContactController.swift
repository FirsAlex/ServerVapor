import Fluent
import Vapor

struct CreateContactRequestBody: Content {
    let name: String
    let telephone: String
    
    func makeContact(_ userID: User.IDValue ) -> Contact {
        return Contact(name: name, telephone: telephone, userID: userID)
    }
}

struct PatchContactRequestBody: Content {
        let name: String?
        let telephone: String?
}

struct ContactController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let todos = routes.grouped("contacts")
            todos.get(use: selectAllContacts)
            todos.delete(use: deleteAllContacts)
        
            todos.group(":contactID") { todo in
                todo.delete(use: deleteContactByID)
                todo.get(use: selectContactByID)
                todo.patch(use: updateContactByID)
            }
            
            todos.group("by_user", ":userID") { todo in
                todo.post(use: insertContact)
                todo.get(use: selectContactsByUserID)
            }
    }
    
    func selectContactsByUserID(req: Request) throws -> EventLoopFuture<[Contact]> {
        guard let userIDString = req.parameters.get("userID"),
              let userID = UUID(userIDString) else {
                throw Abort(.badRequest, reason: "Invalid parameter `userID`")
        }
        return Contact.query(on: req.db).filter(\.$user.$id == userID).all()
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
        return Contact.query(on: req.db).delete().transform(to: .ok) // transform to response status code 200
    }

    func deleteContactByID(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Contact.find(req.parameters.get("contactID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
    
    func updateContactByID(req: Request) throws -> EventLoopFuture<HTTPStatus> {
            guard let contactIDString = req.parameters.get("contactID"),
                let contactID = UUID(contactIDString) else {
                    throw Abort(.badRequest, reason: "Invalid parameter `contactID`")
            }

            let patchContactRequestBody = try req.content.decode(PatchContactRequestBody.self)
            return Contact.find(contactID, on: req.db)
                .unwrap(or: Abort(.notFound))
                .flatMap { contact in
                    if let name = patchContactRequestBody.name {
                        contact.name = name
                    }
                    if let telephone = patchContactRequestBody.telephone {
                        contact.telephone = telephone
                    }
                    return contact.update(on: req.db)
                        .transform(to: .ok)// .map { user }
                }
    }
}
