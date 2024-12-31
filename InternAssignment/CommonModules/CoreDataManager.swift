//
//  CoreDataManager.swift
//  swipeAssignment
//
//  Created by Praval Gautam on 29/12/24.
//
import Foundation
import CoreData

class CoreDataProvider: ObservableObject {
    // Persistent container for Core Data
    static let shared = CoreDataProvider() 
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "ProductData")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error.localizedDescription)")
            } else {
                print("Core Data stack loaded successfully!")
            }
        }
    }
    
    // Function to save a product into Core Data
    func saveProduct(product: Product) {
        let context = container.viewContext
        
        // Create a new FavoriteProduct instance
        let favoriteProduct = FavoriteProduct(context: context)
        
        favoriteProduct.name = product.productName
        favoriteProduct.price = product.price
        favoriteProduct.tax = product.tax
        favoriteProduct.productType = product.productType
        favoriteProduct.image = product.image
        favoriteProduct.isFavourite = true
        
        // Save the context
        do {
            try context.save()
            print("Product saved successfully!")
        } catch {
            print("Error saving product: \(error.localizedDescription)")
        }
    }
    
    // Function to fetch all favorite products
    func fetchFavoriteProducts() -> [FavoriteProduct] {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<FavoriteProduct> = FavoriteProduct.fetchRequest()
        
        do {
            let favoriteProducts = try context.fetch(fetchRequest)
            print("\(favoriteProducts)")
            return favoriteProducts
        } catch {
            print("Error fetching favorite products: \(error.localizedDescription)")
            return []
        }
    }
    
    // Function to delete a product
    func deleteProduct(product: FavoriteProduct) {
        let context = container.viewContext
        context.delete(product)
        
        do {
            try context.save()
            print("Product deleted successfully!")
        } catch {
            print("Error deleting product: \(error.localizedDescription)")
        }
    }
}
