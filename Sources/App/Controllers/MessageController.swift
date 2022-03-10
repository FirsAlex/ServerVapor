import Fluent
import Vapor
import Foundation

struct CreateMessageRequestBody: Content {
    let text: String
    let fromUserID: User.IDValue
    let toUserID: User.IDValue
    
    func makeMessage() -> Message {
        return Message(text: text, fromUserID: fromUserID, toUserID: toUserID)
    }
}

struct PatchMessageRequestBody: Content {
    let text: String?
    let delivered: Bool?
}

struct GetMessageRequestBody: Content {
    let userID: String?
    let contactID: String?
}

struct MessageController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let todos = routes.grouped("messages")
            todos.get(use: selectAllMessages)
            todos.delete(use: deleteAllMessages)
            todos.post(use: insertMessage)
        
            todos.group(":messageID") { todo in
                todo.delete(use: deleteMessageByID)
                todo.get(use: selectMessageByID)
                todo.patch(use: updateMessageByID)
            }
            
            todos.group("by_from_user",":userID") { todo in
                todo.get(use: selectMessageByFromUserID)

            }
        
            todos.group("by_to_user",":userID") { todo in
                todo.get(use: selectMessageByToUserID)
            }
        
            todos.group("between_users") { todo in
                todo.get(use: selectMessageBetweenUsers)
                todo.patch(use: updateDelivered)
            }
    }
    
    func updateDelivered(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let getMessageRequestBody = try req.query.decode(GetMessageRequestBody.self)
        guard let userIDString = getMessageRequestBody.userID,
              let userID = UUID(userIDString),
              let contactIDString = getMessageRequestBody.contactID,
              let contactID = UUID(contactIDString) else {
                throw Abort(.badRequest, reason: "Invalid parameter `userID` or `contactID`")
        }
        return Message.query(on: req.db)
                      .set(\.$delivered, to: true)
                      .group(.and) { group in
                          group.filter(\.$fromUser.$id == contactID)
                               .filter(\.$toUser.$id == userID)
                          .filter(\.$delivered == false)}
                      .update().transform(to: .ok)
    }
    
    func selectMessageBetweenUsers(req: Request) throws -> EventLoopFuture<[Message]> {
        let getMessageRequestBody = try req.query.decode(GetMessageRequestBody.self)
        guard let userIDString = getMessageRequestBody.userID,
              let userID = UUID(userIDString),
              let contactIDString = getMessageRequestBody.contactID,
              let contactID = UUID(contactIDString) else {
                throw Abort(.badRequest, reason: "Invalid parameter `userID` or `contactID`")
        }
        return Message.query(on: req.db).group(.and) { group in
            group.filter(\.$fromUser.$id ~~ [userID, contactID])
                .filter(\.$toUser.$id ~~ [userID, contactID])
        }.sort(\.$createdAt).all()
    }
    
    func selectMessageByFromUserID(req: Request) throws -> EventLoopFuture<[Message]> {
        guard let userIDString = req.parameters.get("userID"),
              let userID = UUID(userIDString) else {
                throw Abort(.badRequest, reason: "Invalid parameter `userID`")
        }
        return Message.query(on: req.db).filter(\.$fromUser.$id == userID).all()
    }
    
    func selectMessageByToUserID(req: Request) throws -> EventLoopFuture<[Message]> {
        guard let userIDString = req.parameters.get("userID"),
              let userID = UUID(userIDString) else {
                throw Abort(.badRequest, reason: "Invalid parameter `userID`")
        }
        return Message.query(on: req.db).filter(\.$toUser.$id == userID).all()
    }
    
    func selectAllMessages(req: Request) throws -> EventLoopFuture<[Message]> {
        return Message.query(on: req.db).all()
    }

    func deleteAllMessages(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Message.query(on: req.db).delete().transform(to: .ok) // transform to response status code 200
    }
    
    func insertMessage(req: Request) throws -> EventLoopFuture<Message> {
        let createMessageRequestBody = try req.content.decode(CreateMessageRequestBody.self)
        let message = createMessageRequestBody.makeMessage()
        return message.save(on: req.db).map { message }
    }
    
    func deleteMessageByID(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Message.find(req.parameters.get("messageID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { $0.delete(on: req.db) }
            .transform(to: .ok)
    }
    
    func selectMessageByID(req: Request) throws -> EventLoopFuture<Message> {
        guard let messageIDString = req.parameters.get("messageID"),
            let messageID = UUID(messageIDString) else {
                throw Abort(.badRequest, reason: "Invalid parameter `messageID`")
        }
        return Message.find(messageID, on: req.db)
            .unwrap(or: Abort(.notFound)) // return 404 if the todo hasn't been found
    }
    
    func updateMessageByID(req: Request) throws -> EventLoopFuture<HTTPStatus> {
            guard let messageIDString = req.parameters.get("messageID"),
                let messageID = UUID(messageIDString) else {
                    throw Abort(.badRequest, reason: "Invalid parameter `messageID`")
            }

            let patchMessageRequestBody = try req.content.decode(PatchMessageRequestBody.self)
            return Message.find(messageID, on: req.db)
                .unwrap(or: Abort(.notFound))
                .flatMap { message in
                    if let text = patchMessageRequestBody.text {
                        message.text = text
                    }
                    if let delivered = patchMessageRequestBody.delivered {
                        message.delivered = delivered
                    }
                    return message.update(on: req.db)
                        .transform(to: .ok)// .map { message }
                }
    }
}
