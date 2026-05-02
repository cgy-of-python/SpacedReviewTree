//
//  Item.swift
//  SpacedReviewTree
//
//  Created by 曹高远 on 2/5/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
