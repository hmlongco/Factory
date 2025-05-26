
import SwiftUI
import FactoryKit

struct ContainerDemoView: View {

    @StateObject var model = ContainerDemoViewModel()

    var body: some View {
        VStack(spacing: 20) {
            Text("Showing \(model.text())")
        }
        .padding()
    }

}

struct ContainerDemoVieww_Previews: PreviewProvider {
    static var previews: some View {
        let _ = DemoContainer.shared.with {
            $0.myServiceType.register { ParameterService(count: 8) }
        }
        ContainerDemoView(model: ContainerDemoViewModel())
    }
}
