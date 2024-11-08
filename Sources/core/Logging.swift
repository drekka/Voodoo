import Foundation

/// Defines how the server will log it's configuration and processing.
public enum LogLevel: Int, CaseIterable {

    /// Used only by the command line, this suppresses all logging except the URL the server is running on.
    ///
    /// This allows shell scripts to read the URL for passing onto other processes.
    case server

    /// (Default) Outputs enough information to see the requests coming in and out of the server.
    case info

    /// Debugging output which includes details of the server's configueration and request processing.
    case debug

    /// USed for debugging Voodoo. This enables debugging on the Hummingbird server as well as Voodoo.
    case `internal`
}

public var voodooLogLevel: LogLevel = .info

/// Outputs a message to the log.
///
/// This only outputs if the passed level is less or equal to the current value of ``voodooLogLevel``.
/// When a ``.debug`` message is printed, the function and line number of the calling function is also
/// prepended.
///
/// - parameters:
///   - level: The logging level of the message. Default `.info`.
///   - file: The file where the logging call originated.
///   - function: The function making the logging call. Usually this is not passed.
///   - line: The line in the function that made the call. Also usually not passed.
///   - message: The message to be logged.
public func voodooLog(level: LogLevel = .info, file: StaticString = #file, fileID: String = #fileID, function: String = #function, line: UInt = #line, _ message: String) {
    if level.rawValue <= voodooLogLevel.rawValue {
        switch level {
        case .server:
            print(message)
        case .debug:
            // Extract the file name then print.
            if let match = fileID.firstMatch(of: #/.*\/(.*)\.swift/#) {
                print("🩻 \(match.1)[\(line)] \(function): \(message)")
            } else {
                print("🩻 \(function)[\(line)]: \(message)")
            }
        default:
            print("💀 \(message)")
        }
    }
}
