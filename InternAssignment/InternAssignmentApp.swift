//
//  InternAssignmentApp.swift
//  InternAssignment
//
//  Created by Praval Gautam on 29/12/24.
//

import SwiftUI

@main
struct InternAssignmentApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AddProductViewModel())
        }
    }
}
