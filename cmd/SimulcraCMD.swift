//
//  Created by Derek Clarkson on 26/9/2022.
//

import ArgumentParser
import Foundation
import SimulcraCore

/// allows us to set a URL as an option type.
extension URL: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(string: argument)
    }
}

/// Provides a command line wrapper around the server.
@main
struct SimulcraCMD: ParsableCommand {

    struct Options: ParsableArguments {

        @Flag(name: .long)
        var verbose = false
    }

    static var configuration: CommandConfiguration {

        return CommandConfiguration(
            commandName: "simulcra",
            abstract: "A simple server designed for testing purposes",
            discussion: """
            This starts and manages a mock server that can be used for testing or development purposes.
            """,
            version: "0.1.0",
            shouldDisplay: true,
            subcommands: [Run.self, DisplayConfiguration.self]
        )
    }
}

extension SimulcraCMD {

    /// The main `run` subcommand.
    struct Run: ParsableCommand {

        static var configuration: CommandConfiguration {
            CommandConfiguration(
                abstract: "Configures and starts the server",
                discussion: """
                This scans the port range (Default: 8080-8090) for the first free port. \
                It then starts the server on that port. This allows for parallel testing. \
                The port range change be changed using the --port-range argument.
                """
            )
        }

        // Global options.
        @OptionGroup var options: SimulcraCMD.Options

        @Option(
            name: [.short, .long],
            help: """
            The port range to start the server on. \
            Must be either a single port or a valid range written as "xxxx-yyyy" where xxxx is the lower bound \
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
            name: [.short, .customLong("template-dir")],
            help: """
            A directory path where response template files can be found. \
            Templates are used to generate response bodies. They can contain mustache template keys to insert data \
            from the server. \
            Reference here: https://hummingbird-project.github.io/hummingbird/current/hummingbird-mustache/mustache-syntax.html
            """
        )
        var templatePath: URL?

        @Option(
            name: [.short, .customLong("config-dir")],
            help: """
            A directory path containing YAML files to configure the server. These files setup the APIs being mocked. \
            see the readme doco for details on all the options that are available.
            """
        )
        var configPath: URL?

        @Option(name: [.short, .customLong("file-dir")],
                help: """
                A directory path where non-template files are sourced from. \
                Mostly locations of image files and other static web like resources. \
                If the server receives a request and does not have an end point configured for it \
                then it scans this directory to see if the request path maps to a stored file.
                """)
        var filePaths: [String] = []

        @Argument(help: "Any number of API scenarios to load.")
        var scenario: [String] = []

        mutating func run() throws {

            if let configPath{
                let loader = ConfigLoader(directory: configPath)
            }

            let server = try Simulcra(portRange: portRange,
                                      templatePath: templatePath,
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

//            guard options.verbose else { return }
//            print("Configuration:")
//            print("\tTemplate path: \(templatePath ?? "")")
//            print("\tConfig path: \(configPath ?? "")")
//            print("\tFile paths:")
//            // filePaths.forEach { print("\t ‣ \($0)") }
//            print("")
        }
    }

    /// Dumps the server's current configuration to assist with debugging.
    struct DisplayConfiguration: ParsableCommand {

        static var configuration: CommandConfiguration {
            CommandConfiguration(
                abstract: "Displays the server's current setup for debugging purposes."
            )
        }

        // @OptionGroup var options: SimulcraCMD.Options

        mutating func run() throws {
            print("")
            print("")
        }
    }
}
