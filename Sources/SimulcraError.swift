//
//  File.swift
//  
//
//  Created by Derek Clarkson on 2/10/21.
//

enum SimulcraError: Error {
    case noAvailablePort
    case unexpectedError(Error)
    case unableToReadFile(String)
    case invalidFileContents(String)
}
