//
//  ModelTest.swift
//  FactoryDemo
//
//  Created by Michael Long on 11/4/23.
//

import FactoryKit
import SwiftUI

struct ModelTest: View {
    @Injected(\.modelData) var modelData: ModelData
    var body: some View {
        HStack {
            Text("Model Preview Test")
            Spacer()
            Text("\(modelData.games.count)")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ModelTest()
        .padding()
}

nonisolated struct ModelData {
    var games: [Int] = []
}

nonisolated struct TestData {
    static let games2: [Int] = [1,9]
    static let games3: [Int] = [1,2,9]
    static let games4: [Int] = [1,2,8,9]
}

extension Container {
    var modelData: Factory<ModelData> {
        self { ModelData() }
            .scope(.session)
            .onPreview { ModelData(games: TestData.games3) }
            .onTest { ModelData(games: TestData.games4) }
//            .onDebug { ModelData(games: TestData.games2) }
    }
}
