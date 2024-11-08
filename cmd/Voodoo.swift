import ArgumentParser
import Foundation
import Voodoo

/// Provides a command line wrapper around the server.
@main
struct Voodoo: ParsableCommand {

    struct Options: ParsableArguments {

        @Option(
            name: .long,
            help: "Sets the logging level."
        )
        var logLevel: LogLevel = .info
    }

    static var configuration: CommandConfiguration {

        CommandConfiguration(
            commandName: "voodoo-server",
            abstract: """
                A mock server that provides APIs and files for debugging, regression and continuous integration testing.
            """,
            version: "0.2.0",
            shouldDisplay: true,
            subcommands: [Run.self]
        )
    }
}
