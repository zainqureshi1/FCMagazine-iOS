//
//  DropboxManager.swift
//  FCMagazine
//
//  Created by Zain on 8/7/17.
//  Copyright © 2017 e2esp. All rights reserved.
//

import Foundation
import SwiftyDropbox

class DropboxManager {
    
    private let ACCESS_TOKEN = "t3HP7BPiD2AAAAAAAAAAHzZCvsP_y-pkY1kv0PCAPSdxi13bKay5dwS0xQbRsWqE"
    private let COVER_PAGES = "Cover Pages"
    
    private static var instance: DropboxManager!
    
    private var dbClient: DropboxClient!
    private var fileManager: FileManager!
    
    private var directoryURL: URL!
    private var coverPagesURL: URL!
    
    static func getInstance() -> DropboxManager {
        if instance == nil {
            instance = DropboxManager()
            instance.initClient()
        }
        return instance
    }
    
    private func initClient() {
        dbClient = DropboxClient(accessToken: ACCESS_TOKEN)
        fileManager = FileManager.default
        directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        coverPagesURL = directoryURL.appendingPathComponent(COVER_PAGES, isDirectory: true)
        if fileManager.fileExists(atPath: coverPagesURL.path) == false {
            try? fileManager.createDirectory(at: coverPagesURL, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    func loadCoverPages() -> [URL] {
        var urls = [URL]()
        if fileManager.fileExists(atPath: coverPagesURL.path) {
            if let fileNames = try? fileManager.contentsOfDirectory(atPath: coverPagesURL.path) {
                for filename in fileNames {
                    urls.append(coverPagesURL.appendingPathComponent(filename))
                }
            }
        }
        return urls
    }
    
    func loadMagazine(name: String) -> [URL] {
        var urls = [URL]()
        let magazineURL = self.directoryURL.appendingPathComponent(name, isDirectory: true)
        if fileManager.fileExists(atPath: magazineURL.path) {
            if let fileNames = try? fileManager.contentsOfDirectory(atPath: magazineURL.path) {
                for filename in fileNames {
                    urls.append(magazineURL.appendingPathComponent(filename))
                }
            }
        }
        return urls
    }
    
    func getCoverPagesMeta(success: @escaping ((Array<Files.Metadata>) -> Void), failure: @escaping ((String) -> Void)) {
        dbClient.files.listFolder(path: "/\(COVER_PAGES)/").response(completionHandler: {response, error in
            if let result = response {
                success(result.entries)
            } else if let error = error {
                failure(error.description)
            }
        })
    }
    
    func getMagazineMeta(name: String, success: @escaping ((Array<Files.Metadata>) -> Void), failure: @escaping ((String) -> Void)) {
        dbClient.files.listFolder(path: "/\(name)/").response(completionHandler: {response, error in
            if let result = response {
                success(result.entries)
            } else if let error = error {
                failure(error.description)
            }
        })
    }
    
    func downloadCoverPages(doDownload: @escaping ((Array<Files.Metadata>) -> Bool), recursiveSuccess: @escaping ((Files.FileMetadata, URL) -> Void), completion: @escaping ((URL) -> Void), failure: @escaping ((String) -> Void)) {
        getCoverPagesMeta(success: {entries in
            if doDownload(entries) {
                self.downloadRecursive(entries: entries, at: 0, saveIn: self.coverPagesURL, recursiveSuccess: recursiveSuccess, completion: completion, failure: failure);
            }
        }, failure: failure)
    }
    
    func downloadMagazine(name: String, progress: @escaping ((Int, Int) -> Void), completion: @escaping ((URL) -> Void), failure: @escaping ((String) -> Void)) {
        getMagazineMeta(name: name, success: {entries in
            let magazineURL = self.directoryURL.appendingPathComponent(name, isDirectory: true)
            if self.fileManager.fileExists(atPath: magazineURL.absoluteString) == false {
                try? self.fileManager.createDirectory(at: magazineURL, withIntermediateDirectories: true, attributes: nil)
            }
            let total = entries.count
            var downloaded = 0
            progress(total, downloaded)
            self.downloadRecursive(entries: entries, at: 0, saveIn: magazineURL, recursiveSuccess:
            {_, _ in
                downloaded += 1
                progress(total, downloaded)
            }, completion: completion, failure: failure);
        }, failure: failure)
    }
    
    func downloadRecursive(entries: Array<Files.Metadata>, at index: Int, saveIn destination: URL, recursiveSuccess: ((Files.FileMetadata, URL) -> Void)?, completion: ((URL) -> Void)?, failure: @escaping ((String) -> Void)) {
        if (entries.count <= index) {
            completion?(destination)
            return
        }
        let fileMeta = entries[index]
        dbClient.files.download(path: fileMeta.pathLower!, overwrite: true, destination: { temporaryURL, response in
            return destination.appendingPathComponent(fileMeta.name)
        }).response(completionHandler: { response, error in
            if let response = response {
                recursiveSuccess?(response.0, response.1)
                self.downloadRecursive(entries: entries, at: index + 1, saveIn: destination, recursiveSuccess: recursiveSuccess, completion: completion, failure: failure)
            } else if let error = error {
                print(error)
                failure(error.description)
            }
        })
    }
    
    func deleteMagazine(name: String) {
        let magazineURL = self.directoryURL.appendingPathComponent(name, isDirectory: true)
        try? fileManager.removeItem(at: magazineURL)
    }
    
}
