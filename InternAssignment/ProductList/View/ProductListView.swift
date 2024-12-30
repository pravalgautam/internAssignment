//
//  ProductListView.swift
//  swipeAssignment
//
//  Created by Praval Gautam on 28/12/24.
//

import SwiftUI
import CoreData

struct ProductListView: View {
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"
    @StateObject private var viewModel = ProductListViewModel()
    @Environment(\.managedObjectContext) var moc
    @State private var selectedImage: UIImage? 
    // Use a single @FetchRequest for FavoriteProduct
    @FetchRequest(
        entity: FavoriteProduct.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FavoriteProduct.name, ascending: true)]
    ) var favoriteProducts: FetchedResults<FavoriteProduct>
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 1, green: 0.9, blue: 0.85).ignoresSafeArea()
                
                VStack {
                    HStack {
                        SearchBar(searchText: $searchText)
                    }
                    .padding(.horizontal)
                    
                    categories(selectedCategory: $selectedCategory)
                    HStack {
                        Text("Favourites")
                            .font(.title3)
                            .foregroundStyle(.orange)
                            .padding(.leading, 16)
                            .padding(.vertical, 8)


                        Spacer()
                    }

                    FavoriteProductsView()
                    
                    ZStack {
                        Color(red: 1, green: 0.9, blue: 0.85).opacity(0.8).ignoresSafeArea(.all)
                        ScrollView {
                            Spacer()
                            if viewModel.isLoading {
                                ActivityIndicator()
                                .frame(width: 50, height: 50)
                            } else if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .padding()
                            } else {
                                ProductsGrid(products: filteredProducts)
                            }
                            Spacer()
                        }
                        .refreshable {
                                                   refreshData()
                                               }
                        .padding(.bottom)
                    }
                    .cornerRadius(40)
                    .ignoresSafeArea()
                    .onAppear {
                        viewModel.fetchProducts()
                    }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink {
                            AddProductView()
                                .navigationBarBackButtonHidden()
                        } label: {
                            Circle()
                                .fill(Color.orange)
                                .frame(height: 50)
                                .overlay {
                                    Image(systemName: "plus")
                                        .foregroundStyle(.white)
                                        .font(.title3)
                                }
                        }
                    }
                    .padding(.horizontal, 30)
                }
            }
        }
    }
    // Delete a specific product immediately from favorites
     func deleteFavoriteProduct(_ product: FavoriteProduct) {
         let context = moc
         
         // Delete the selected product from Core Data
         context.delete(product)
         
         // Save the context after deletion
         do {
             try context.save()
         } catch {
             print("Error deleting product: \(error.localizedDescription)")
         }
     }
    
    private var filteredProducts: [Product] {
        var products = viewModel.products
        
        if selectedCategory != "All" {
            products = products.filter { $0.productType.lowercased() == selectedCategory.lowercased() }
        }
        
        if !searchText.isEmpty {
            products = products.filter { $0.productName.lowercased().contains(searchText.lowercased()) }
        }
        
        return products
    }
    private func refreshData() {
           viewModel.isLoading = true
           viewModel.fetchProducts()
       }
}


struct SearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
        ZStack {
            HStack {
                TextField("Search", text: $searchText)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .foregroundColor(.black)
                    .padding(.leading, 8)
                    .autocapitalization(.none)
            }
        }

    }
}


struct categories: View {
    @Binding var selectedCategory: String
    
    // Sample dynamic categories array
    let categoryList = ["All", "Shoes", "Electronics", "Service", "Product", "Clothing", "Others"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ZStack {
                HStack(spacing: 10) {
                    ForEach(categoryList, id: \.self) { category in
                        Text(category)
                            .padding()
                            .foregroundColor(selectedCategory == category ? .black : .white) // Highlight selected category
                            .background(
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(selectedCategory == category ? Color.white : Color.orange)
                                    .stroke(selectedCategory == category ? Color.white : Color.white, lineWidth: 2)
                                    .frame(height: 30)
                            )
                            .onTapGesture {
                                selectedCategory = category // Update selected category
                            }
                    }
                }   .padding(.leading,16)
            }
        }
    }
}

struct ProductsGrid: View {
    let products: [Product]
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(
        entity: FavoriteProduct.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FavoriteProduct.name, ascending: true)]
    ) var favoriteProducts: FetchedResults<FavoriteProduct>

    var body: some View {
        let columns = [
            GridItem(.flexible(), spacing: 20),
            GridItem(.flexible(), spacing: 20)
        ]

        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(products) { product in
                    ZStack(alignment: .topTrailing) {
                        // Card Background
//                        RoundedRectangle(cornerRadius: 16)
//                            .stroke(Color.black, lineWidth: 1.0)

                        VStack(alignment: .leading, spacing: 12) {
                            // Product Image
                            AsyncImage(url: URL(string: product.image.isEmpty ? "defaultImageURL" : product.image)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 140, height: 140)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 140, height: 140)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                case .failure:
                                    Image("defaultImage")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 140, height: 140)
                                        .background(Color.gray.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 10)

                            // Product Name
                            Text(product.productName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 10)

                            // Product Details
                            VStack(alignment: .leading, spacing: 4) {
                                Text("₹\(String(format: "%.2f", product.price))")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)

                                Text(product.productType)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)

                                Text("Tax: ₹\(String(format: "%.2f", product.tax))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                        }
                        .background(Color.white)
                        .cornerRadius(16)

                        // Favorite Button
                        Button(action: {
                            toggleFavorite(product: product)
                        }) {
                            Image(systemName: isFavorite(product: product) ? "heart.fill" : "heart")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(isFavorite(product: product) ? Color.orange : Color.white)
                                .frame(width: 24, height: 24)
                                .padding(8)
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
    }

    // Check if a product is a favorite
    private func isFavorite(product: Product) -> Bool {
        favoriteProducts.contains { $0.id == product.id }
    }


    // Toggle favorite status
    private func toggleFavorite(product: Product) {
        if let favorite = favoriteProducts.first(where: { $0.id == product.id }) {
            // Remove from favorites
            moc.delete(favorite)
        } else {
            // Add to favorites
            let newFavorite = FavoriteProduct(context: moc)
            newFavorite.id = product.id
            newFavorite.name = product.productName
            newFavorite.price = product.price
            newFavorite.image = product.image
            newFavorite.productType = product.productType
            newFavorite.isFavourite = true
        }

        do {
            try moc.save()
        } catch {
            print("Failed to save favorite: \(error.localizedDescription)")
        }
        
    }
    


}

struct FavoriteProductsView: View {
    @FetchRequest(
        entity: FavoriteProduct.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \FavoriteProduct.name, ascending: true)]
    ) var favoriteProducts: FetchedResults<FavoriteProduct>
    
    @Environment(\.managedObjectContext) var moc
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(favoriteProducts) { product in
                    HStack(spacing: 8) {
                        // Compact Product Image
                        AsyncImage(url: URL(string: (product.image ?? "").isEmpty ? "defaultImageURL" : product.image!)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 100, height: 100)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            case .failure:
                                Image("defaultImage")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100) // Reduced size
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8)) // Adjusted corner radius
                            @unknown default:
                                EmptyView()
                            }
                        }
                        
                        VStack(alignment: .leading,spacing:4) {
                            // Compact Product Name
       
                                Text(product.name ?? "Unnamed Product")
                                    .font(.system(size: 16, weight: .semibold)) // Reduced font size
                                    .foregroundColor(.black)
                                    .lineLimit(2) // Limit to 1 line
                                    .truncationMode(.tail) // Truncate overflow text
                                
                                // Compact Product Price
                                Text("₹\(String(format: "%.2f", product.price))")
                                    .font(.system(size: 12, weight: .bold)) // Reduced font size
                                    .foregroundColor(.black)
                                
                                // Compact Product Type
                                Text(product.productType ?? "Unknown Type")
                                    .font(.system(size: 10)) // Reduced font size
                                    .foregroundColor(.gray)
                     
                        }.padding(.bottom)
                        
                        
                        Spacer()

                        // Delete Button (Trash Icon)
                        Button(action: {
                            deleteFavoriteProduct(product)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.system(size: 18))
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                    .padding(2) // Reduced padding
                    .background(Color.white)
                    .cornerRadius(8) // Adjusted corner radius
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2) // Reduced shadow radius
                }
            }
            .padding(.horizontal, 5) // Reduced horizontal padding
            .padding(.leading,16)
        }
    }
    
    // Delete a specific favorite product from Core Data
    private func deleteFavoriteProduct(_ product: FavoriteProduct) {
        let context = moc
        
        context.delete(product)
        
        do {
            try context.save()
        } catch {
            print("Error deleting product: \(error.localizedDescription)")
        }
    }
}


#Preview {
    ProductListView()
}
