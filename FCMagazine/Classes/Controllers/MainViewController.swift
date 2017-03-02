//
//  MainViewController.swift
//  FCMagazine
//
//  Created by Zain on 2/28/17.
//  Copyright © 2017 e2esp. All rights reserved.
//

import UIKit

private let reuseIdentifierLatest = "LatestCoverCell"
private let reuseIdentifierMagazine = "MagazineCoverCell"
private let reuseIdentifierHeader = "SectionHeader"
private let latestCoverPerRow: CGFloat = 1
private let magazineCoverPerRow: CGFloat = 2
private let sectionInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 20.0, right: 0.0)
private let segueIdentifierReader = "ReaderSegue"

class MainViewController: UICollectionViewController {
    
    // MARK: - Properties
    var sections = [Section]()
    var patternedImageColor: UIColor!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifierLatest)
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifierMagazine)

        patternedImageColor = UIColor(patternImage: UIImage(named: "Tile")!)
        
        self.loadMagazineSections()
    }
    
    func loadMagazineSections() {
        var latestMagazines = [Magazine]()
        latestMagazines.append(Magazine("Latest Issue FEB 2017", withCover: UIImage(named: "LatestIssueCover")!, "Issue40", andPageCount: 58))
        sections.append(Section("LATEST ISSUE", withItemsPerRow: 1, andMagazines: latestMagazines))
        
        var recentMagazines = [Magazine]()
        recentMagazines.append(Magazine("JAN 2017", withCover: UIImage(named: "MagazineCover1")!, "Issue39", andPageCount: 56))
        sections.append(Section("RECENT ISSUES", withItemsPerRow: 2, andMagazines: recentMagazines))
        
        adjustSectionsSize()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func adjustSectionsSize() {
        for section in sections {
            while section.magazines.count % section.itemsPerRow != 0 {
                section.magazines.append(Magazine(isFiller: true))
            }
        }
    }
    
    func magazine(for indexPath: IndexPath) -> Magazine {
        return sections[indexPath.section].magazines[indexPath.row]
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdentifierReader {
            let readerViewController = segue.destination as! ReaderViewController
            let indexPath = sender as! IndexPath
            readerViewController.magazineItem = sections[indexPath.section].magazines[indexPath.row]
        }
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].magazines.count
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                             withReuseIdentifier: reuseIdentifierHeader,
                                                                             for: indexPath) as! SectionHeaderView
            headerView.backgroundColor = patternedImageColor
            headerView.labelHeader.text = sections[indexPath.section].heading
            return headerView
        default:
            assert(false, "Unexpected element kind")
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = indexPath.section == 0 ? reuseIdentifierLatest : reuseIdentifierMagazine
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MagazineCoverCell
        let magazine = self.magazine(for: indexPath)
        
        cell.backgroundColor = patternedImageColor
        if magazine.filler {
            cell.imageViewCover.isHidden = true
            cell.labelName.isHidden = true
        } else {
            cell.imageViewCover.image = magazine.cover
            cell.labelName.text = magazine.name
        
            if indexPath.section == 0 {
                cell.labelName.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/10)
            }
        }
    
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !magazine(for: indexPath).filler {
            performSegue(withIdentifier: segueIdentifierReader, sender: indexPath)
        }
    }
    
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */
    
}

extension MainViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            let paddingSpace = sectionInsets.left * (latestCoverPerRow + 1)
            let availableWidth = view.frame.width - paddingSpace
            let widthPerItem = availableWidth / latestCoverPerRow
            return CGSize(width: widthPerItem, height: widthPerItem*0.7)
        }
        
        let paddingSpace = sectionInsets.left * (magazineCoverPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / magazineCoverPerRow
        return CGSize(width: widthPerItem, height: widthPerItem*1.48)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
    
}
