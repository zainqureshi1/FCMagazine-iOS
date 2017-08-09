//
//  MagazineCoverCell.swift
//  FCMagazine
//
//  Created by Zain on 2/28/17.
//  Copyright © 2017 e2esp. All rights reserved.
//

import UIKit

class MagazineCoverCell: UICollectionViewCell {
    
    @IBOutlet weak var imageViewCover: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelAvailable: UILabel!
    @IBOutlet weak var buttonDownload: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    
    private var magazine: Magazine?
    private var downloadHandler: ((Magazine) -> Void)?
    
    func setCover(_ magazine: Magazine, downloadHandler: @escaping ((Magazine) -> Void)) {
        self.magazine = magazine
        self.downloadHandler = downloadHandler
        imageViewCover.image = magazine.coverImage
        labelName.text = magazine.name
        buttonDownload.isHidden = magazine.downloaded || magazine.downloading
        labelAvailable.isHidden = !magazine.downloaded || magazine.downloading
        progressView.isHidden = !magazine.downloading
        if magazine.downloading {
            progressView.progress = Float(magazine.downloadedPages) / Float(magazine.totalPages)
        }
    }
    
    @IBAction func downloadClicked(_ sender: Any) {
        if let magazine = magazine {
            downloadHandler?(magazine)
        }
    }
    
}
