//
//  ProductListViewModel.swift
//  swipeAssignment
//
//  Created by Praval Gautam on 28/12/24.
//

import Foundation
import Combine

class ProductListViewModel: ObservableObject {
    @Published var products: [Product] = [] // Published property to bind data to the view
    @Published var isLoading = false // Indicates whether the data is being loaded
    @Published var errorMessage: String? // Handles error messages

    private var cancellables = Set<AnyCancellable>() // For Combine subscriptions

    func fetchProducts() {
        let urlString = "https://app.getswipe.in/api/public/get" // Replace with your actual API URL
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL"
            return
        }

        isLoading = true // Start loading
        errorMessage = nil // Reset error message
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data) // Extract data
            .decode(type: [Product].self, decoder: JSONDecoder()) // Decode JSON to Product array
            .receive(on: DispatchQueue.main) // Receive on main thread for UI updates
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false // Stop loading
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.errorMessage = error.localizedDescription // Handle errors
                }
            }, receiveValue: { [weak self] products in
                self?.products = products // Update products
            })
            .store(in: &cancellables)
    }
}

