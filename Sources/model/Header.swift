//
//  File.swift
//
//
//  Created by Derek Clarkson on 27/10/2022.
//

import Foundation

/// Code completion and keys for common HTTP headers.
public enum Header {

    public static let contentType = "content-type"
    public static let location = "content-type"

    public enum ContentType {
        public static let  textPlain = "text/plain"
        public static let  textHTML = "text/html"
        public static let  applicationJSON = "application/json"
        public static let  applicationYAML = "application/yaml"
        public static let  applicationFormData = "application/x-www-form-urlencoded"
    }
}
