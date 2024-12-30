//
//  AddProductView.swift
//  swipeAssignment
//
//  Created by Praval Gautam on 29/12/24.
//
import SwiftUI
import Combine
import UIKit
import Network
import Foundation

struct AddProductView: View {
    @StateObject private var viewModel = AddProductViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var isImagePickerPresented = false
    @State private var selectedFormat: String = "JPEG"
    @State private var showFormatOptions = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @EnvironmentObject var sharedViewModel: AddProductViewModel
    @State private var isSaveSuccessful = false

    var body: some View {
        ZStack {
            Color(red: 1, green: 0.9, blue: 0.85).ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(Color.orange)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    Spacer()
                    Text("Add Product")
                        .font(.title2)
                        .foregroundStyle(.orange)
                        .bold()
                    Spacer()
                }
                VStack {
                    // Button to show the format selection
                    Button(action: {
                        showFormatOptions = true
                    }) {
                        ZStack {
                            Rectangle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .cornerRadius(10)
                            
                            if let selectedImage = viewModel.selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Rectangle())
                                    .cornerRadius(10)
                            } else {
                                Image(systemName: "photo.fill")
                                    .foregroundColor(.white)
                                    .font(.title)
                            }
                        }
                    }
                }
                .actionSheet(isPresented: $showFormatOptions) {
                    ActionSheet(
                        title: Text("Select Image Format"),
                        buttons: [
                            .default(Text("JPEG")) {
                                selectedFormat = "JPEG"
                                isImagePickerPresented = true
                            },
                            .default(Text("PNG")) {
                                selectedFormat = "PNG"
                                isImagePickerPresented = true
                            },
                            .cancel()
                        ]
                    )
                }
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePickerController(selectedImage: $viewModel.selectedImage)
                        .onDisappear {
                            validateImage()
                        }
                }
                
                VStack {
                    ScrollView {
                        VStack(alignment: .leading) {
                            Text("Select Product Type")
                                .font(.headline)
                                .foregroundStyle(.orange)
                                .padding(.bottom, 5)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(viewModel.productTypes, id: \.self) { type in
                                        Button(action: {
                                            viewModel.productType = type
                                        }) {
                                            Text(type)
                                                .font(.system(size: 10, weight: .semibold))
                                                .padding()
                                                .frame(minWidth: 100)
                                                .background(viewModel.productType == type ? Color.white : Color.orange)
                                                .foregroundColor(viewModel.productType == type ? Color.orange : .white)
                                                .cornerRadius(12)
                                                .padding(.vertical, 5)
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 15)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Product Name")
                                .font(.headline)
                                .padding(.bottom, 5)
                                .foregroundStyle(.orange)
                            TextField("Enter Product Name", text: $viewModel.productName)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .autocapitalization(.none)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Price")
                                .font(.headline)
                                .padding(.bottom, 5)
                                .foregroundStyle(.orange)
                            TextField("Enter Price", text: $viewModel.price)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .autocapitalization(.none)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Tax")
                                .font(.headline)
                                .padding(.bottom, 5)
                                .foregroundStyle(.orange)
                            TextField("Enter Tax", text: $viewModel.tax)
                                .textFieldStyle(RoundedTextFieldStyle())
                                .autocapitalization(.none)
                        }
                        
                        Button(action: {
                            validateFields()
                        }) {
                            Text(viewModel.isLoading ? "Submitting..." : "Add Product")
                                .foregroundColor(.white)
                                .padding()
                                .cornerRadius(8)
                        }
                        .disabled(viewModel.isLoading)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 50)
                                .fill(Color.orange)
                                .frame(height: 50)
                        )
                    }
                }
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Validation Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onReceive(viewModel.$isSuccessful) { isSuccessful in
                if isSuccessful {
                    alertMessage = viewModel.message
                    showAlert = true
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(viewModel.isSuccessful ? "Success" : "Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"), action: {
                        if viewModel.isSuccessful {
                            dismiss()
                        }
                    })
                )
            }
        }
    }
    
    private func validateFields() {
        if viewModel.productName.isEmpty {
            alertMessage = "Product name cannot be empty."
            showAlert = true
            return
        }
        
        if viewModel.price.isEmpty || Double(viewModel.price) == nil || Double(viewModel.price)! <= 0 {
            alertMessage = "Please enter a valid price."
            showAlert = true
            return
        }
        
        if viewModel.tax.isEmpty || Double(viewModel.tax) == nil || Double(viewModel.tax)! < 0 {
            alertMessage = "Please enter a valid tax percentage."
            showAlert = true
            return
        }
        
        if viewModel.productType.isEmpty {
            alertMessage = "Please select a product type."
            showAlert = true
            return
        }
        
        if viewModel.selectedImage == nil {
            alertMessage = "Please select an image."
            showAlert = true
            return
        }
        
        viewModel.addProduct()
    }
    
    private func validateImage() {
        guard let image = viewModel.selectedImage else { return }
        let size = image.size
        if size.width == size.height {
            alertMessage = "Please select an image with a 1:1 aspect ratio."
            showAlert = true
            viewModel.selectedImage = nil
        }
    }
    
    
}

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white)
            )
    }
}
