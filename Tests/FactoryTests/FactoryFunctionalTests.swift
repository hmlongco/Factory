import XCTest
@testable import Factory

typealias OpenURLFunction = (_ url: URL) -> Bool

extension Container {
    static let openURL = Factory<OpenURLFunction> {
        { _ in false }
    }
}

private class MyViewModel {
    @Injected(Container.openURL) var openURL
    func open(site: String) {
        _ = openURL(URL(string: site)!)
    }
}

class OpenURLFunctionMock {
    var openedURL: URL?
    init() {
        Container.openURL.register {
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
        Container.Registrations.reset()
        Container.Scope.reset()
    }


    func testOpenFuctionality() throws {
        var openedURL: URL?
        Container.openURL.register {
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

