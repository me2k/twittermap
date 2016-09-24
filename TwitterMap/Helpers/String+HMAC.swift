//
//  String+HMAC.swift
//  TwitterMap
//
//  Created by Myles Eynon on 15/08/2016.
//  Copyright © 2016 MylesEynon. All rights reserved.
//

import Foundation

extension String {
    //generate a HMAC-SHA1 signature.
    func hmac(key: String) -> String {
        let cStringKey = key.cStringUsingEncoding(NSUTF8StringEncoding)
        let data = self.cStringUsingEncoding(NSUTF8StringEncoding)
        var result = [CUnsignedChar](count: Int(CC_SHA1_DIGEST_LENGTH), repeatedValue: 0)
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), cStringKey!, Int(strlen(cStringKey!)), data!, Int(strlen(data!)), &result)
        let hmacData = NSData(bytes: result, length: Int(CC_SHA1_DIGEST_LENGTH))
        let hmacBase64 = hmacData.base64EncodedDataWithOptions(NSDataBase64EncodingOptions.Encoding76CharacterLineLength)
        return String(NSString(data: hmacBase64, encoding: NSUTF8StringEncoding)!)
    }
    
}
