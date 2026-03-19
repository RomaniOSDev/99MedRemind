//
//  SaveService.swift
//  99MedRemind
//
//  Created by Fedele Avella on 19.03.2026.
//
//

import Foundation

struct SaveService {
    
    static var lastUrl: URL? {
        get { UserDefaults.standard.url(forKey: "LastUrl") }
        set { UserDefaults.standard.set(newValue, forKey: "LastUrl") }
    }
}
