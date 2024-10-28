import Testing
import Voodoo
import Yams

extension Testing.Tag {
    @Tag static var decoding: Self
    @Tag static var http: Self
}

@Suite("HTTP endpoint decoding tests", .tags(.decoding))
struct DecodingTests {

    @Test(.tags(.http)) func emptyResponse() throws {
        let yaml = """
        """.data(using: .utf8)!
        let endpoint = try YAMLDecoder().decode(HTTPEndpoint.self, from: yaml)
        guard case .ok = endpoint.response else {
            Issue.record("Did not receive an .ok response")
            return
        }
    }

//    @Test(.tags(.http)) func simpleOkResponse() throws {
//        let yaml = """
//        http:
//          api: get /abc
//        response:
//          status: 200
//        """.data(using: .utf8)!
//        let decoder = YAMLDecoder()
//        guard case .ok = try decoder.decode(HTTPEndpoint.self, from: yaml) else {
//            Issue.record("Did not receive an .ok response")
//            return
//        }
//    }
}
