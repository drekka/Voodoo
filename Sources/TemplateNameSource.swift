//
//  Created by Derek Clarkson on 28/8/2022.
//

/// Apply to anything that can generate the names of response templates.
///
/// Response templates are expected to be Mustache based templates stored in the
/// directory references by the server's `templatePath` property.
public protocol TemplateNameSource {

    /// The value to store in the HTTP "Content-type" header of the response.
    var contentType: String { get }

    /// Return the name of the template.
    ///
    /// Usually this takes the form of the path to the template within the template directory structure.
    var templateName: String { get }
}
