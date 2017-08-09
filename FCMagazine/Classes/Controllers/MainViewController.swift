//
//  MainViewController.swift
//  FCMagazine
//
//  Created by Zain on 2/28/17.
//  Copyright © 2017 e2esp. All rights reserved.
//

import UIKit

private let reuseIdentifierMagazine = "MagazineCoverCell"
private let sectionInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 20.0, right: 0.0)
private let segueIdentifierReader = "ReaderSegue"

class MainViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, MagazineDeleteDelegate {
    
    // MARK: - Properties
    var magazines = [Magazine]()
    let dateFormatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.gray
        self.navigationController?.navigationBar.tintColor = UIColor.black
        self.navigationItem.title = "Fashion & LifeStyle Monthly Magazine"
        let rightButtonItem = UIBarButtonItem.init(image: UIImage(named: "Icon Menu"), style: .plain, target: self, action: #selector(showMenu))
        self.navigationItem.rightBarButtonItem = rightButtonItem
        
        dateFormatter.dateFormat = "MMM yyyy"
        
        self.loadMagazineCovers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.lockOrientation(.portrait, andRotateTo: .portrait)
        }
    }
    
    func showMenu() {
        Utility.showActionSheet(viewController: self, sourceView: nil, title: nil, message: nil, actionTitle: "Subscribe", handler: {_ in
            
        })
    }
    
    func loadMagazineCovers() {
        let coverPageUrls = DropboxManager.getInstance().loadCoverPages()
        if coverPageUrls.count > 0 {
            magazines.removeAll()
            for url in coverPageUrls {
                addCoverPage(url, checkExisting: false, refreshView: false)
            }
            refreshCollectionView(true)
        }
        
        let loadedCoversFromStorage = magazines.count > 0
        DropboxManager.getInstance().downloadCoverPages(doDownload: {entries in
            if entries.count == self.magazines.count {
                var missingCovers = false
                for entry in entries {
                    var hasCover = false
                    for magazine in self.magazines {
                        if magazine.name == entry.name {
                            hasCover = true
                            break
                        }
                    }
                    if hasCover == false {
                        missingCovers = true
                        break
                    }
                }
                return missingCovers
            }
            return true
        }, recursiveSuccess: {fileMeta, url in
            self.addCoverPage(url, checkExisting: loadedCoversFromStorage, refreshView: true)
        }, completion: {url in
            
        }, failure: {error in
            if self.magazines.count == 0 {
                Utility.showAlert(viewController: self, title: "Loading Error", message: error)
            }
        })
    }
    
    func addCoverPage(_ url: URL, checkExisting: Bool, refreshView: Bool) {
        let name = url.deletingPathExtension().lastPathComponent
        if let image = UIImage(contentsOfFile: url.path), let date = dateFormatter.date(from: name) {
            if checkExisting {
                for magazine in magazines {
                    if magazine.name == name {
                        magazine.coverImage = image;
                        refreshCollectionItem(magazine)
                        return
                    }
                }
            }
            let magazine = Magazine(name, image, date)
            magazines.append(magazine)
            refreshCollectionView(true)
            checkMagazine(magazine, refreshView: refreshView)
        }
    }
    
    func checkMagazine(_ magazine: Magazine, refreshView: Bool) {
        let fileUrls = DropboxManager.getInstance().loadMagazine(name: magazine.name)
        if fileUrls.count > 0 {
            magazine.downloaded = true
            magazine.fileUrls = fileUrls
            if refreshView {
                refreshCollectionItem(magazine)
            }
            
            DropboxManager.getInstance().getMagazineMeta(name: magazine.name, success: {entries in
                if magazine.fileUrls?.count != entries.count {
                    magazine.downloaded = false
                    self.refreshCollectionItem(magazine)
                }
            }, failure: {error in
            })
        } else if magazine.downloaded {
            magazine.downloaded = false
            magazine.fileUrls = nil
            if refreshView {
                refreshCollectionItem(magazine)
            }
        }
    }
    
    func refreshCollectionView(_ sort: Bool) {
        if sort {
            magazines.sort(by: { $0.date.compare($1.date) == .orderedDescending })
        }
        self.collectionView?.reloadData()
    }
    
    func refreshCollectionItem(_ magazine: Magazine) {
        let loadedItems = self.collectionView?.numberOfItems(inSection: 0)
        for i in 0..<min(magazines.count, loadedItems!) {
            if magazines[i].name == magazine.name {
                self.collectionView?.reloadItems(at: [IndexPath(row: i, section:0)])
                return
            }
        }
    }
    
    func downloadMagazine(_ magazine: Magazine) {
        DropboxManager.getInstance().downloadMagazine(name: magazine.name, progress: {total, downloaded in
            magazine.downloading = true
            magazine.totalPages = total
            magazine.downloadedPages = downloaded
            self.refreshCollectionItem(magazine)
        }, completion: {url in
            magazine.downloading = false
            self.checkMagazine(magazine, refreshView: true)
        }, failure: {error in
            magazine.downloading = false
            self.checkMagazine(magazine, refreshView: true)
            Utility.showAlert(viewController: self, title: "Downloading Error", message: error)
         })
    }

    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return magazines.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifierMagazine, for: indexPath) as! MagazineCoverCell
        cell.setCover(self.magazines[indexPath.row], downloadHandler: {magazine in
            self.downloadMagazine(magazine)
        })
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let magazine = self.magazines[indexPath.row]
        if magazine.downloaded {
            performSegue(withIdentifier: segueIdentifierReader, sender: indexPath)
        } else if magazine.downloading {
            Utility.showAlert(viewController: self, title: magazine.name, message: "Please wait while this magazine is downloading")
        } else {
            Utility.showMultiActionAlert(viewController: self, title: magazine.name, message: "Do you want to download this magazine?", actionTitles: ["Start Download", "Not Yet"], handlers: [{action in
                    self.downloadMagazine(magazine)
                }])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let horizontalMargin = flowLayout.sectionInset.left + flowLayout.sectionInset.right
        let viewWidth = collectionView.bounds.width - horizontalMargin
        let imageSize = magazines[indexPath.row].coverImage.size
        let pictureHeight:CGFloat = viewWidth * (imageSize.height / imageSize.width)
        let textHeightAndMargin:CGFloat = 42
        let cellHeight:CGFloat = pictureHeight + textHeightAndMargin
        return CGSize(width: viewWidth, height: cellHeight)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdentifierReader {
            let readerViewController = segue.destination as! ReaderViewController
            let indexPath = sender as! IndexPath
            readerViewController.deleteDelegate = self
            readerViewController.magazineItem = magazines[indexPath.row]
        }
    }
    
    // MARK: - Magazine Delete Delegate
    
    func deleted(magazine: Magazine) {
        checkMagazine(magazine, refreshView: true)
    }
    
}
