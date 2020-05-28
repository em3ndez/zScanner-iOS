//
//  NewDocumentMediaViewModel.swift
//  zScanner
//
//  Created by Jakub Skořepa on 14/08/2019.
//  Copyright © 2019 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift
import RxRelay
import AVFoundation

class NewDocumentMediaViewModel {
    
    // MARK: Instance part
    private let tracker: Tracker
    let mediaType: MediaType
    let folderName: String
    let mediaArray = BehaviorRelay<[Media]>(value: [])
    
    init(folderName: String, mediaType: MediaType, tracker: Tracker) {
        self.tracker = tracker
        self.mediaType = mediaType
        self.folderName = folderName
    }
    
    // MARK: Interface
    func addMedia(_ media: Media) {
        // Checking for adding media multiple times after reedit
        guard mediaArray.value.firstIndex(of: media) == nil else { return }
        
        // Tracking
        tracker.track(.galleryUsed(media.fromGallery))
        
        // Add media
        var newArray = mediaArray.value
        newArray.append(media)
        mediaArray.accept(newArray)
    }
    
    func removeMedia(_ media: Media) {
        // Tracking
        tracker.track(.deleteImage)

        // Remove media
        var newArray = mediaArray.value
        _ = newArray.remove(media)
        mediaArray.accept(newArray)
    }
}
