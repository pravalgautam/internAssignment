//
//  ProductModel.swift
//  swipeAssignment
//
//  Created by Praval Gautam on 28/12/24.
//

import Foundation

struct Product: Identifiable, Codable {
    let id = UUID() 
    let image: String
    let price: Double
    let productName: String
    let productType: String
    let tax: Double

    enum CodingKeys: String, CodingKey {
        case image
        case price
        case productName = "product_name"
        case productType = "product_type"
        case tax
    }
}
