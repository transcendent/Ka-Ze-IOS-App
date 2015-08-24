/* Copyright 2015 Deloitte. Inc

This file is part of Ka-Ze-IOS-App.

Ka-Ze-IOS-App is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

Ka-Ze-IOS-App is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Ka-Ze-IOS-App.  If not, see https://github.com/transcendent/ka-ze-rails-app/blob/master/LICENSE
*/

import Foundation
import MapKit

class Incident: NSObject, MKAnnotation {
    
    var id:String
    var subject:String?
    var incidentDescription:String?
    var accountName:String
    var status:String?
    var latitude:Double {
        didSet {
            coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        }
    }
    var longitude:Double {
        didSet {
            coordinate = CLLocationCoordinate2DMake(latitude, longitude)
        }
    }
    var lastModified:NSDate
    var caseNumber:String?
    var closedDate:NSDate?
    var coordinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(0,0)
    
    override init() {
        id = ""
        accountName = ""
        latitude = 0
        longitude = 0
        lastModified = NSDate()
    }
    
}
