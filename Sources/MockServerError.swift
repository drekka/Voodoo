//
//  Created by Derek Clarkson on 20/9/2022.
//

import Foundation

public enum MockServerError: Error {
    case conversionError(String)
    case templateRender(String)
    case noPortAvailable
    case unexpectedError(Error)
}

