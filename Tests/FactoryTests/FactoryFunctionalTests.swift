import XCTest
@testable import Factory

typealias OpenURLFunction = (_ url: URL) -> Bool

extension Container {
    var openURL: Factory<OpenURLFunction> {
        makes { { _ in false } }
    }
}

private class MyViewModel {
    @Injected(\.openURL) var openURL
    func open(site: String) {
        _ = openURL(URL(string: site)!)
    }
}

class OpenURLFunctionMock {
    var openedURL: URL?
    init() {
        Container.shared.openURL.register {
            { [weak self] url in
                self?.openedURL = url
                return false
            }
        }
    }
}

final class FactoryFunctionalTests: XCTestCase {

    override func setUp() {
        super.setUp()
        Container.shared = Container()
    }


    func testOpenFuctionality() throws {
        var openedURL: URL?
        Container.shared.openURL.register {
            { url in
                openedURL = url
                return false
            }
        }
        let viewModel = MyViewModel()
        viewModel.open(site: "https://google.com")
        XCTAssert(openedURL != nil)
    }

    func testMockFuctionality() throws {
        let mock = OpenURLFunctionMock()
        let viewModel = MyViewModel()
        viewModel.open(site: "https://google.com")
        XCTAssert(mock.openedURL != nil)
    }

}

