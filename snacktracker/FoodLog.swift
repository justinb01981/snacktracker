//
//  FoodLog.swift
//  snacktracker
//
//  Created by Justin Brady on 2/19/21.
//  Copyright © 2021 Justin Brady. All rights reserved.
//

import Foundation

class FoodLog {
    
    static var shared: FoodLog = FoodLog()
    
    var dateFormatter: DateFormatter
    var fileManager: FileManager
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd: hh:mm:ss"
        
        fileManager = FileManager.default
        
        do {
            try fileManager.createDirectory(at: logPath, withIntermediateDirectories: true, attributes: nil)
        }
        catch let err {
            print("failed to create directory: \(err)")
        }
    }
    
    func saveDetails(forImageAtPath imagePath: URL, details: FoodDetailsModel) {
        
        let detailStr = "\(details.name!),\(details.servingSize!),\(details.tag!),\(dateFormatter.string(from: details.time!)),\(details.type!)"
        
        do {
            let data = detailStr.data(using: .utf8)
            try data?.write(to: imagePath.appendingPathExtension("txt"))
        }
        catch let err {
            print(err)
        }
    }
    
    func retrieveDetails(forImageAtPath imagePath: URL) -> FoodDetailsModel? {
        
        var details = FoodDetailsModel()
        var content: String
        
        do {
            let data = try Data(contentsOf: imagePath.appendingPathExtension("txt"))
            content = String(data: data, encoding: .utf8)!
        }
        catch let err {
            print(err)
            return nil
        }

        let components = content.components(separatedBy: ",")
        
        print(content)
        
        details.name = components[0]
        details.servingSize = components[1]
        details.tag = components[2]
        details.time = dateFormatter.date(from: components[3])
        details.type = MealTypeEnum(rawValue: components[4])
        
        if details.name == "" {
            details.name = "Unknown"
        }
        
        return details
    }
    
    var logPath: URL {
        get {
            return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
    }
    
    var logDirectory: URL {
        get {
            return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        }
    }
    
    var enumeratedEntries: [URL] {
        get {
            var manifest: [URL] = []
            var files: [URL] = []
            var creationTimes: [URL: Date] = [:]
            
            do {
                files = try fileManager.contentsOfDirectory(at: logPath, includingPropertiesForKeys: nil)
            }
            catch {
                return []
            }
            
            for file in files {
                // convert this URL to a file-path:
                let sClean = file.path //file.absoluteString.replacingOccurrences(of: "file://", with: "")
                
                if sClean[sClean.index(sClean.endIndex, offsetBy: -3)..<sClean.endIndex] != "jpg" {
                    files.removeAll(where: { $0 == file})
                    continue
                }
                
                guard let attrs = try? fileManager.attributesOfItem(atPath: sClean) else {
                    fatalError()
                }
                creationTimes[file] = attrs[FileAttributeKey.creationDate] as? Date
            }
            
            // sort by creation-time
            files.sort { (aURL, bURL) -> Bool in
                return Date().timeIntervalSince(creationTimes[aURL]!) < Date().timeIntervalSince(creationTimes[bURL]!)
            }
            
            for file in files {
                manifest.append(URL(string: file.absoluteString)!)
            }
            
            return manifest
        }
    }
}
