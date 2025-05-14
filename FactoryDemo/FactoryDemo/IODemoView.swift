//
//  IODemoView.swift
//  FactoryDemo
//
//  Created by Michael Long on 5/27/23.
//

import FactoryKit
import SwiftUI

protocol IODemoViewing: ObservableObject {

}

class IODemoViewModel: IODemoViewing {

}

extension Container {
    var demoViewing: Factory<any IODemoViewing> {
        self { IODemoViewModel() }
    }
}

struct IODemoView1<VM:IODemoViewing>: View {
    @StateObject var viewModel: VM
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

//struct IODemoView2<VM:IODemoViewing>: View {
//    @InjectedObject(\Container.demoViewing) var viewModel: VM
//    var body: some View {
//        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
//    }
//}


struct IODemoView_Previews: PreviewProvider {
    static var previews: some View {
        IODemoView1(viewModel: IODemoViewModel())
    }
}
