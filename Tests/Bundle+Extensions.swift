//
//  Created by Derek Clarkson on 13/9/21.
//

import UIKit

extension Bundle {
    
    static var testBundle: Bundle = {
        let testBundlePath = Bundle(for: SimulcraTests.self).resourcePath
        return Bundle(path: testBundlePath! + "/Simulcra_SimulcraTests.bundle")!
    }()
}
