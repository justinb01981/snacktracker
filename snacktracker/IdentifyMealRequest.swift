//
//  IdentifyMealRequest.swift
//  snacktracker
//
//  Created by Justin Brady on 2/19/21.
//  Copyright © 2021 Justin Brady. All rights reserved.
//

import Foundation
import UIKit

class IdentifyMealRequest: NSObject {
    private var internalRequest: NSMutableURLRequest!
    private var afterResponse: (IdentifyMealRequest)->Void = { request in }
    
    class Result: Decodable {
        class Prediction: Decodable {
            var probability: Float = 0
            var tagId: String = ""
            var tagName: String = ""
        }
        var created: String = ""
        var predictions: [Prediction] = []
    }
    
    var result: Result?
    
    init(_ image: UIImage) {
        super.init()
        
        internalRequest = NSMutableURLRequest(url: URL(string: "https://www.de-vis-software.ro/foodivisus.aspx")!)
        
        guard let plistUser = Bundle.main.infoDictionary?["kFoodivisusUser"] as? String,
            let plistPassword = Bundle.main.infoDictionary?["kFoodivisusPass"] as? String else {
                fatalError("must enter kFoodivisusUser and kFoodivisusPass in info.plist (see IdentifyMealRequest.init)")
        }
        
        // your credentials encoded in base64
        let username = plistUser
        let password = plistPassword
        let loginData = String(format: "%@:%@", username, password).data(using: String.Encoding.utf8)!
        let base64LoginData = loginData.base64EncodedString()
        let headers = ["Authorization" : "Basic \(base64LoginData)",
                       "Content-Type": "application/json", "Accept": "application/json"]
 
        internalRequest.httpMethod = "POST"
        internalRequest.allHTTPHeaderFields = headers
        internalRequest.httpBody = "{ \"base64_Photo_String\": \"\(image.jpegData(compressionQuality: 1.0)!.base64EncodedString())\", \"photo_url\":\"NO\" }".data(using: .utf8)
        
        print(String(data: internalRequest.httpBody!, encoding: .utf8)!)
    }
    
    func perform(_ then: @escaping (IdentifyMealRequest)->Void) {
        guard let conn = NSURLConnection(request: internalRequest as URLRequest, delegate: self) else {
            fatalError()
        }
        
        afterResponse = then
        print("starting")
        conn.start() // this won't block, right?
        print("...done")
    }

}

extension IdentifyMealRequest: NSURLConnectionDelegate, NSURLConnectionDataDelegate {
    
    func connection(_ connection: NSURLConnection, didFailWithError error: Error) {
        print("connection failed with error:\(error)")
        afterResponse(self)
    }

    func connection(_ connection: NSURLConnection, didReceive data: Data) {
        
        let decoder = JSONDecoder()
        var d: [String: String] = [:]
        
        if let obj = try? decoder.decode(Result.self, from: data) as Result {
            self.result = obj
        }
        
        afterResponse(self)
    }
}

class IdentifyMealManager: NSObject {
    
    static var shared: IdentifyMealManager = IdentifyMealManager()
    
    func identify(_ image: UIImage, then doThen: @escaping (IdentifyMealRequest)->Void) {
        
        let request = IdentifyMealRequest(image)
        request.perform { (mealRequest) in
            doThen(mealRequest)
        }
    }
}
