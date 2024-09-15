//
//  Created by Derek Clarkson on 26/9/2022.
//

import ArgumentParser
import Foundation
import PathKit
import Voodoo

/// Provides a command line wrapper around the server.
@main
struct Voodoo: ParsableCommand {

    struct Options: ParsableArguments {

        @Flag(name: .long)
        var verbose = false
    }

    static var configuration: CommandConfiguration {

        CommandConfiguration(
            commandName: "voodoo",
            abstract: "A mock server that provides APIs and files for debugging, regression and continuous integration testing.",
            version: "0.1.0",
            shouldDisplay: true,
            subcommands: [Run.self]
        )
    }
}

extension Voodoo {

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
        @OptionGroup var options: Voodoo.Options

        @Flag(
            name: [.long],
            help: """
            Activates trace mode in the Hummingbird server for tracking errors.
            """
        )
        var hummingbirdVerbose = false

        @Flag(
            name: .customLong("use-any-addr"),
            help: """
            By default the server uses 127.0.0.1 as it's IP address. However that will not work in containers suck as Docker where 0.0.0.0 is need. Enabling this \
            flag sets the server's IP to the any address (0.0.0.0). However be aware that this may cause firewalls and other security software to flag the server.
            """
        )
        var useAnyAddr = false

        @Option(
            name: .shortAndLong,
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
        var templatePath: Path?

        @Option(
            name: .shortAndLong,
            help: """
            either a directory path containing YAML files or a reference to a particular file. \
            If a directory is referenced then all YAML files in the directory will be loaded. \
            If a specific file is referenced then the end points in that file and any files it references \
            will be loaded. \
            See the readme doco for details on all the options that are available.
            """
        )
        var config: Path

        @Option(name: [.short, .customLong("file-dir")],
                help: """
                A directory path where non-template files are sourced from. \
                Mostly locations of image files and other static web like resources. \
                If the server receives a request and does not have an end point configured for it \
                then it scans this directory to see if the request path maps to a stored file.
                """)
        var filePaths: [Path] = []

        mutating func run() throws {

            do {
                let endpoints = try ConfigLoader(verbose: options.verbose).load(from: config)
                let server = try VoodooServer(portRange: portRange,
                                              useAnyAddr: useAnyAddr,
                                              templatePath: templatePath,
                                              filePaths: filePaths,
                                              verbose: options.verbose) { endpoints }
                server.wait()
            } catch DecodingError.dataCorrupted(let context) {
                print("💀 Decoding error: \(context.codingPath.map(\.stringValue)) - \(context.debugDescription) \(String(describing: context.underlyingError))")
                throw ExitCode.failure
            } catch {
                print("💀 Error: \(error.localizedDescription)")
                throw ExitCode.failure
            }
        }

        mutating func validate() throws {
            try filePaths.forEach {
                if !$0.exists {
                    throw ValidationError("File directory invalid: \($0)")
                }
            }
        }
    }
}
