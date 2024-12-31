//
//  ContentView.swift
//  InternAssignment
//
//  Created by Praval Gautam on 29/12/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var coreDataProvider = CoreDataProvider()
    var body: some View {
      ProductListView()
            .environment(\.managedObjectContext, coreDataProvider.container.viewContext)
    }
}

#Preview {
    ContentView()
}
