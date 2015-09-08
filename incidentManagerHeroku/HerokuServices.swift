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

class HerokuServices {
    
    private var integrationUserName:String!
    private var integrationUserPassword:String!
    private var herokuHost:String!
    
    init() {
        // very useful piece of code for reading settings and setting defaults taken from
        // http://stackoverflow.com/questions/6291477/how-to-retrieve-values-from-settings-bundle-in-objective-c
        var standardUserDefaults = NSUserDefaults.standardUserDefaults()
        var settings : AnyObject? = standardUserDefaults.objectForKey("integrationUser")
        if  settings == nil {
            self.registerDefaultsFromSettingsBundle();
        }
        
        integrationUserName = standardUserDefaults.objectForKey("integrationUser") as! String!
        integrationUserPassword = standardUserDefaults.objectForKey("integrationUserPassword") as! String!
        herokuHost = standardUserDefaults.objectForKey("host") as! String!
    }
    

    // very useful piece of code for reading settings and setting defaults taken from
    // http://stackoverflow.com/questions/6291477/how-to-retrieve-values-from-settings-bundle-in-objective-c
    
    func registerDefaultsFromSettingsBundle() {
        // this function writes default settings as settings
        var settingsBundle = NSBundle.mainBundle().pathForResource("Settings", ofType: "bundle")
        if settingsBundle == nil {
            NSLog("Could not find Settings.bundle");
            return
        }
        var settings = NSDictionary(contentsOfFile:settingsBundle!.stringByAppendingPathComponent("Root.plist"))!
        var preferences: [NSDictionary] = settings.objectForKey("PreferenceSpecifiers") as! [NSDictionary];
        var defaultsToRegister = NSMutableDictionary(capacity:(preferences.count));
        
        for prefSpecification:NSDictionary in preferences {
            var key: NSCopying? = prefSpecification.objectForKey("Key")as! NSCopying?
            if key != nil {
                defaultsToRegister.setObject(prefSpecification.objectForKey("DefaultValue")!, forKey: key!)
            }
        }
        NSUserDefaults.standardUserDefaults().registerDefaults(defaultsToRegister as [NSObject : AnyObject]);
    }
    
    
    // builds the basic authorization header to keep devise happy
    private func buildBasicAuthHeader() -> String {
        var authorizationString:String = integrationUserName + ":" + integrationUserPassword
        var authorizationData:NSData = authorizationString.dataUsingEncoding(NSUTF8StringEncoding)!
        var base64EncodedAuthorization:String = authorizationData.base64EncodedStringWithOptions(nil)
        return base64EncodedAuthorization
    }
    
    // updates an incident in Heroku
    func updateIncidentInHeroku(incident:Incident, successCallback:(() -> Void), failureCallback:(message:String) -> Void) {
        var getEndpoint: String = "https://" + herokuHost + "/incidents/" + incident.id + ".json"
        var urlRequest = NSMutableURLRequest(URL: NSURL(string: getEndpoint)!)
        urlRequest.HTTPMethod = "PUT"
        urlRequest.setValue("Basic \(buildBasicAuthHeader())", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var params:Dictionary<String, String> = Dictionary<String, String>()
        
        if let descriptionText = incident.incidentDescription {
            params["description"] = descriptionText
        }
        if let statusText = incident.status {
            params["status"] = statusText
        }
        
        var err: NSError?
        urlRequest.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: nil, error: &err)
        // make the call
        NSURLConnection.sendAsynchronousRequest(urlRequest, queue: NSOperationQueue(), completionHandler:{
            data, response, error -> Void in
            if let anError = error {
                // send the error back for display
                failureCallback(message: error.description)
            }
            println (NSString(data:response, encoding: NSUTF8StringEncoding))
            successCallback()
            
        })
        
    }
    
    
    // pulls the incidents from Heroku
    func getIncidentsFromHeroku(successCallback: (incidents:[Incident]) -> Void, failureCallback:(message:String) -> Void) {
        var getEndpoint: String = "https://" + herokuHost + "/incidents.json"
        var urlRequest = NSMutableURLRequest(URL: NSURL(string: getEndpoint)!)
        urlRequest.HTTPMethod = "GET"
        urlRequest.setValue("Basic \(buildBasicAuthHeader())", forHTTPHeaderField: "Authorization")
        
        var incidents:[Incident] = [Incident]()
        
        // make the call
        NSURLConnection.sendAsynchronousRequest(urlRequest, queue: NSOperationQueue(), completionHandler:{
            (response:NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            if let anError = error {
                // send the error back for display
                failureCallback(message: error.description)
            }
            else {
                // parse out the json message into the incidents
                var jsonError: NSError?
                let incidentArray = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &jsonError) as! NSArray
                
                if let aJSONError = jsonError {
                    // send the error back for display
                    failureCallback(message: error.description)
                }
                else {
                    for record in incidentArray  {
                        // map the attributes from the dictionary into the incident object
                        var incident:Incident = Incident()
                        
                        var dateTimeFormatter = NSDateFormatter()
                        dateTimeFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
                        
                        var dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        
                        incident.id = String(record["id"] as! Int)
                        incident.caseNumber = record["incident_number"] as? String
                        
                        var firstName = record["first_name"] as! String
                        var lastName = record["last_name"] as! String
                        incident.accountName = firstName + " " + lastName
                        
                        incident.status = record["status"] as? String
                        incident.subject = record["subject"] as? String
                        incident.incidentDescription = record["description"] as? String
                        
                        if let lastModifiedDateObject:AnyObject = record["updated_at"] {
                            incident.lastModified = dateTimeFormatter.dateFromString(lastModifiedDateObject as! String)!
                        }
                        if let closedDateObject:AnyObject = record["closed_date"] {
                            if (!(closedDateObject is NSNull)) {
                                incident.closedDate = dateFormatter.dateFromString(closedDateObject as! String)!
                            }
                        }
                        if let latitudeObject:AnyObject = record["latitude"]  {
                            if (!(latitudeObject is NSNull)) {
                                incident.latitude = (latitudeObject as! NSString).doubleValue
                            }
                        }
                        if let longitudeObject:AnyObject = record["longitude"] {
                            if (!(longitudeObject is NSNull)) {
                                incident.longitude = (longitudeObject as! NSString).doubleValue
                            }
                        }
                        incidents.append(incident)
                    }
                    successCallback(incidents:incidents)
                }
            }
        })
    }
}
