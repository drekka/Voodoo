//
//  Created by Derek Clarkson on 26/9/2022.
//

import ArgumentParser
import Foundation
import SimulcraCore

/// Provides a command line wrapper around the server.
@main
struct SimulcraCMD: ParsableCommand {

    struct Options: ParsableArguments {

        @Flag(name: .shortAndLong)
        var verbose = false
    }

    static var configuration: CommandConfiguration {
        CommandConfiguration(
            commandName: "simulcra",
            abstract: "A simple server designed for testing purposes",
            discussion: """
            This starts and manages a mock server that can be used for testing or development purposes.
            """,
            subcommands: [Run.self, DisplayConfiguration.self],
            defaultSubcommand: Run.self
        )
    }
}

extension SimulcraCMD {

    /// The main `run` subcommand.
    struct Run: ParsableCommand {

        static var configuration: CommandConfiguration {
            CommandConfiguration(
                abstract: "Configures and starts the server"
            )
        }

        // Global options.
        @OptionGroup var options: SimulcraCMD.Options

        @Option(
            name: [.long],
            help: """
            The port range to start the server on. \
            Must be either a single port or a valid range written as \"xxxx-yyyy\" where xxxx is the lower bound \
            of the range and yyyy is upper.
            """,
            transform: { value in

                // Use a regex to extract the parts of the range from the text.
                let valueRange = NSRange(location: 0, length: value.utf8.count)
                let expression = try! NSRegularExpression(pattern: #"(?<lower>\d+)-(?<upper>\d+)"#)

                if let match = expression.firstMatch(in: value, range: valueRange),
                   let lowerRange = Range(match.range(withName: "lower"), in: value),
                   let lower = Int(String(value[lowerRange])),
                   let upperRange = Range(match.range(withName: "upper"), in: value),
                   let upper = Int(String(value[upperRange])),
                   lower <= upper {
                    return lower ... upper
                }

                if let port = Int(value) {
                    return port ... port
                }

                throw ValidationError("""
                Invalid port range. \
                Port range must be either a single port number, or a range in the form xxxx-yyyy where \
                xxxx < yyyy. ie. 8080-9090, 12345-13000, etc.
                """)
            }
        )
        var portRange: ClosedRange<Int> = 8080 ... 8090

        @Option(
            name: [.customShort("t"), .customLong("template-dir")],
            help: """
            A directory path where response template files can be found. \
            Templates are used to generate response bodies. They can contain mustache template keys to insert data \
            from the server. \
            Reference here: https://hummingbird-project.github.io/hummingbird/current/hummingbird-mustache/mustache-syntax.html
            """
        )
        var templatePath: String?

//        @Option(name: [.customLong("file-dir")],
//                help: "A directory path where files are stored. Mostly locations of image files and other web like resources.")
//        var filePaths: [String] = []

//        @Argument(help: "Any number of API scenarios to load.")
//        var scenario: [String] = []

        mutating func run() throws {

            var templatePathURL: URL?
            if let templatePath = templatePath {
                templatePathURL = URL(fileURLWithPath: templatePath)
            }
            let server = try MockServer(portRange: portRange,
                                        templatePath: templatePathURL,
                                        verbose: options.verbose)

            // Load the scenarios.
//            try scenario.forEach { name in
//                guard let scenario = MockAPI.Scenario(rawValue: name) else {
//                    throw ValidationError("Unknown scenario \(name) requested")
//                }
//                server.addMockAPIs(scenario)
//            }

//            filePaths.map { URL(fileURLWithPath: $0) }.forEach { server.addFileDirectory($0) }

            server.wait()
        }

        mutating func validate() throws {

            // Validate passed file directories
//            try filePaths.forEach {
//                var isDirectory: ObjCBool = false
//                guard FileManager.default.fileExists(atPath: $0, isDirectory: &isDirectory) else {
//                    throw ValidationError("Directory not found: \($0)")
//                }
//                if !isDirectory.boolValue {
//                    throw ValidationError("\($0) does not refer to a valid directory")
//                }
//            }

            // validate scenarios
        }

        private func logConfiguration() {

            guard options.verbose else { return }

            print("Configuration:")
            print("\tTemplate path: \(templatePath)")

            print("\tFile paths:")
            // filePaths.forEach { print("\t ‣ \($0)") }
            print("")
        }
    }

    /// Dumps the server's current configuration to assist with debugging.
    struct DisplayConfiguration: ParsableCommand {

        static var configuration: CommandConfiguration {
            CommandConfiguration(
                abstract: "Displays the server's current setup for debugging purposes."
            )
        }

        @OptionGroup var options: SimulcraCMD.Options

        mutating func run() throws {
            print("")
            print("")
        }
    }
}
