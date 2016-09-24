//
//  String+URLEncode.swift
//  TwitterMap
//
//  Created by Myles Eynon on 15/08/2016.
//  Copyright © 2016 MylesEynon. All rights reserved.
//

import Foundation

extension String {

    func urlEncode() -> String {
        let generalDelimitersToEncode = ":#[]@?/!$&'()*+,;="
        let allowedCharacterSet = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
        allowedCharacterSet.removeCharactersInString(generalDelimitersToEncode)
        
        let escaped = self.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacterSet) ?? self
        return escaped
    }

}
