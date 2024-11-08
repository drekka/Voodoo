import ArgumentParser
import Foundation
import Voodoo

extension Voodoo {

    /// The main `run` subcommand.
    struct Run: ParsableCommand {

        static var configuration: CommandConfiguration {
            CommandConfiguration(
                abstract: "Configures and starts Voodoo",
                discussion: """
                This starts by scanning for a free port within a specified range (8080-8090 by default). \
                The server is then started on the free port and it's configuration loaded. \
                The port range change be changed using the --port-range argument.

                Note that if embedding this command in a script where you need to retrieve the server URL, \
                add the '--log-level server' argument to ensure that Voodoo returns the URL to the script. \
                Then use something like:

                export SERVER_URL=`voodoo-server run --log-level server …`

                To retrieve the URL so it can be passed to your test suites.
                """
            )
        }

        // Global options.
        @OptionGroup var options: Voodoo.Options

        @Flag(
            name: .customLong("use-any-addr"),
            help: """
            By default the server uses 127.0.0.1 as it's IP address. However that will not work in containers such as Docker. Enabling this \
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
                if let match = value.firstMatch(of: #/(?<lower>\d+)-(?<upper>\d+)/#),
                   let lower = Int(match.1),
                   let upper = Int(match.2),
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
            name: .shortAndLong,
            help: """
            either a directory path containing YAML files or a reference to a particular file. \
            If a directory is referenced then all YAML files in the directory will be loaded. \
            If a specific file is referenced then the end points in that file and any files it references \
            will be loaded. \
            See the readme doco for details on all the options that are available.
            """
        )
        var config: URL

        @Option(name: [.short, .customLong("file-dir")],
                help: """
                A directory path where non-template files are sourced from. \
                Mostly locations of image files and other static web like resources. \
                If the server receives a request and does not have an end point configured for it \
                then it scans this directory to see if the request path maps to a stored file.
                """)
        var filePaths: [URL] = []

        mutating func run() throws {

            voodooLogLevel = options.logLevel

            do {
                let endpoints = try ConfigLoader().load(from: config)
                let server = try VoodooServer(portRange: portRange,
                                              useAnyAddr: useAnyAddr,
                                              templatePath: templatePath,
                                              filePaths: filePaths) { endpoints }
                server.wait()
            } catch let DecodingError.dataCorrupted(context) {
                voodooLog("Decoding error: \(context.codingPath.map(\.stringValue)) - \(context.debugDescription) \(String(describing: context.underlyingError))")
                throw ExitCode.failure
            } catch {
                voodooLog("Error: \(error.localizedDescription)")
                throw ExitCode.failure
            }
        }

        mutating func validate() throws {
            try filePaths.forEach {
                if $0.fileSystemStatus == .notFound {
                    throw ValidationError("File directory invalid: \($0.filePath)")
                }
            }
        }
    }
}
