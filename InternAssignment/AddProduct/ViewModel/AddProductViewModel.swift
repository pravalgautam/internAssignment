//
//  AddProductViewModel.swift
//  InternAssignment
//
//  Created by Praval Gautam on 30/12/24.
//

import Foundation
import UIKit
import Combine

class AddProductViewModel: ObservableObject {
    @Published var productName = ""
    @Published var price = ""
    @Published var tax = ""
    @Published var productType = ""
    @Published var selectedImage: UIImage? = nil
    
    @Published var isLoading = false
    @Published var message = ""
    @Published var isSuccessful = false
    @Published var showSuccessMessage = false
    
    private let connectivityMonitor = ConnectivityMonitor()
    @Published var isConnected = false
    
    let productTypes = [ "Shoes", "Electronics", "Service", "Product", "Clothing", "Others"]
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        
        connectivityMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.isConnected = connected
                if connected {
                    self?.uploadSavedProducts()
                }
            }
            .store(in: &cancellables)
    }
    
    var isFormValid: Bool {
        return !productName.isEmpty && !price.isEmpty && !tax.isEmpty && !productType.isEmpty
    }
    
    func addProduct() {
        guard isFormValid else {
            message = "Please ensure all fields are filled out correctly."
            return
        }
        
        // Check internet connection and save data in UserDefaults if no connection
        if isConnected {
            uploadProductToServer(productName: productName, price: price, tax: tax, productType: productType, image: selectedImage)
        } else {
            print("No internet connection - saving locally")
            saveProductLocally()
        }
    }
    
    private func uploadProductToServer(productName: String, price: String, tax: String, productType: String, image: UIImage?) {
        isLoading = true
        
        // Create the request and send the product to the server
        guard let url = URL(string: "https://app.getswipe.in/api/public/add") else {
            message = "Invalid URL."
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Append product details to body
        appendProductToBody(&body, boundary: boundary, productName: productName, price: price, tax: tax, productType: productType)
        
        // If there's an image saved locally, add it to the body
        if let image = image,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            let filename = "product.jpg"
            let mimetype = "image/jpeg"
            
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"files[]\"; filename=\"\(filename)\"\r\n")
            body.append("Content-Type: \(mimetype)\r\n\r\n")
            body.append(imageData) // Append the raw image data
            body.append("\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.message = "Error: \(error.localizedDescription)"
                } else if let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) {
                    self.message = "Product added successfully!"
                    self.isSuccessful = true
                    self.showSuccessMessage = true
                } else {
                    self.message = "Error: Server returned status code \((response as! HTTPURLResponse).statusCode)."
                    self.isSuccessful = false
                }
            }
        }
        task.resume()
    }
    
    private func appendProductToBody(_ body: inout Data, boundary: String, productName: String, price: String, tax: String, productType: String) {
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"product_name\"\r\n\r\n")
        body.append("\(productName)\r\n")
        
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"price\"\r\n\r\n")
        body.append("\(price)\r\n")
        
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"tax\"\r\n\r\n")
        body.append("\(tax)\r\n")
        
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"product_type\"\r\n\r\n")
        body.append("\(productType)\r\n")
    }
    
    private func saveProductLocally() {
        print("Starting to save product locally")
        var productData: [String: Any] = [
            "product_name": productName,
            "price": price,
            "tax": tax,
            "product_type": productType,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Save image if available
        if let image = selectedImage,
           let imageName = saveImageLocally(image) {
            productData["image_name"] = imageName
            print("Image saved with name: \(imageName)")
        }
        
        // Retrieve existing products
        let userDefaults = UserDefaults.standard
        var savedProducts = userDefaults.array(forKey: "savedProducts") as? [[String: Any]] ?? []
        
        // Add new product
        savedProducts.append(productData)
        
        // Save back to UserDefaults
        userDefaults.set(savedProducts, forKey: "savedProducts")
        userDefaults.synchronize() // Force immediate save
        
        print("Product saved locally. Total products saved: \(savedProducts.count)")
        message = "Product saved locally due to no internet connection."
        isSuccessful = false
        showSuccessMessage = true
        
        // Verify the save
        if let verification = userDefaults.array(forKey: "savedProducts") as? [[String: Any]] {
            print("Verification - Products in UserDefaults: \(verification.count)")
        } else {
            print("Verification failed - No products found in UserDefaults")
        }
    }
    
    func printSavedProductData() {
        let userDefaults = UserDefaults.standard
        print("Attempting to read saved products...")
        
        if let savedProducts = userDefaults.array(forKey: "savedProducts") as? [[String: Any]] {
            print("Found \(savedProducts.count) saved products")
            for (index, product) in savedProducts.enumerated() {
                print("Product \(index + 1):")
                print("- Name: \(product["product_name"] ?? "Unknown")")
                print("- Price: \(product["price"] ?? "Unknown")")
                print("- Tax: \(product["tax"] ?? "Unknown")")
                print("- Type: \(product["product_type"] ?? "Unknown")")
                
                if let imageName = product["image_name"] as? String,
                   let image = loadImageFromLocal(imageName) {
                    print("- Image found: \(imageName)")
                } else {
                    print("- No image found")
                }
                print("-------------------")
            }
        } else {
            print("No saved product data found in UserDefaults")
        }
    }
    
    private func saveImageLocally(_ image: UIImage) -> String? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            return fileName
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    private func loadImageFromLocal(_ fileName: String) -> UIImage? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    // Function to upload saved products when internet is restored
    private func uploadSavedProducts() {
        guard let savedProducts = UserDefaults.standard.array(forKey: "savedProducts") as? [[String: Any]] else {
            return
        }
        
        guard !savedProducts.isEmpty else { return }
        
        print("Internet restored - Attempting to upload \(savedProducts.count) saved products")
        
        let dispatchGroup = DispatchGroup()
        var successfulUploads: [Int] = []
        
        for (index, product) in savedProducts.enumerated() {
            dispatchGroup.enter()
            
            // Extract product data
            guard let productName = product["product_name"] as? String,
                  let price = product["price"] as? String,
                  let tax = product["tax"] as? String,
                  let productType = product["product_type"] as? String else {
                dispatchGroup.leave()
                continue
            }
            
            // Load image if available
            var productImage: UIImage? = nil
            if let imageName = product["image_name"] as? String {
                productImage = loadImageFromLocal(imageName)
            }
            
            // Upload to server
            uploadProductToServer(productName: productName,
                                  price: price,
                                  tax: tax,
                                  productType: productType,
                                  image: productImage) { success in
                if success {
                    successfulUploads.append(index)
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            // Remove successfully uploaded products from UserDefaults
            if !successfulUploads.isEmpty {
                var remainingProducts = savedProducts
                // Remove in reverse order to maintain correct indices
                for index in successfulUploads.sorted(by: >) {
                    remainingProducts.remove(at: index)
                }
                UserDefaults.standard.set(remainingProducts, forKey: "savedProducts")
                
                self?.message = "Successfully uploaded \(successfulUploads.count) saved products"
                self?.showSuccessMessage = true
                
                print("Successfully uploaded \(successfulUploads.count) products. \(remainingProducts.count) products remaining in local storage.")
            }
        }
    }
    
    private func uploadProductToServer(productName: String, price: String, tax: String, productType: String, image: UIImage?, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let url = URL(string: "https://app.getswipe.in/api/public/add") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Append product details to body
        appendProductToBody(&body, boundary: boundary, productName: productName, price: price, tax: tax, productType: productType)
        
        // If there's an image, add it to the body
        if let image = image,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            let filename = "product.jpg"
            let mimetype = "image/jpeg"
            
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"files[]\"; filename=\"\(filename)\"\r\n")
            body.append("Content-Type: \(mimetype)\r\n\r\n")
            body.append(imageData)
            body.append("\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error uploading saved product: \(error.localizedDescription)")
                    completion(false)
                } else if let response = response as? HTTPURLResponse,
                          (200...299).contains(response.statusCode) {
                    completion(true)
                } else {
                    print("Error: Server returned status code \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                    completion(false)
                }
            }
        }
        task.resume()
    }
}
// Extension to append data to a `Data` object
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
