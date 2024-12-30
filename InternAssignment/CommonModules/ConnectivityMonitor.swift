//
//  ConnectivityMonitor.swift
//  InternAssignment
//
//  Created by Praval Gautam on 30/12/24.
//

import Foundation
import Network

class ConnectivityMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected: Bool = true
    
    init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
}
