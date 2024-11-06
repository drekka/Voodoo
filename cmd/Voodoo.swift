import ArgumentParser
import Foundation

/// Provides a command line wrapper around the server.
@main
struct Voodoo: ParsableCommand {

    struct Options: ParsableArguments {

        @Flag(name: .long)
        var verbose = false
    }

    static var configuration: CommandConfiguration {

        CommandConfiguration(
            commandName: "voodoo-server",
            abstract: "A mock server that provides APIs and files for debugging, regression and continuous integration testing.",
            version: "0.2.0",
            shouldDisplay: true,
            subcommands: [Run.self]
        )
    }
}

