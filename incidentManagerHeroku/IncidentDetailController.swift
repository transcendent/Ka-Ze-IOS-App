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
import UIKit

class IncidentDetailController: UITableViewController {
    
    var incident:Incident!
    
    @IBOutlet weak var caseNumberTextField: UITextField!
    @IBOutlet weak var accountNameTextField: UITextField!
    @IBOutlet weak var subjectTextField: UITextField!
    @IBOutlet weak var activeSwitch: UISwitch!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // set the UI based on the loaded incident
        caseNumberTextField.text = incident.caseNumber
        accountNameTextField.text = incident.accountName
        subjectTextField.text = incident.subject
        activeSwitch.on = (incident.status != "Closed")
        descriptionTextView.text = incident.incidentDescription
        
        // add the save button to the navigation bar
        let saveButtonItem:UIBarButtonItem = UIBarButtonItem(title: "Save", style: .Plain, target: self, action: "updateIncident")
        self.navigationItem.rightBarButtonItem = saveButtonItem
        
        // add a done button to the toolbars for the description and name fields
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: Selector("doneButtonPressed"))
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        descriptionTextView.inputAccessoryView = keyboardToolbar
    
        }
        

    func updateIncident() {
        // update the incident based on the UI
        if activeSwitch.on {
            incident.status = "New"
        }
        else {
            incident.status = "Closed"
        }
        incident.incidentDescription = descriptionTextView.text
        
        // send the request to update the record in Heroku
        activityIndicator.startAnimating()
        HerokuServices().updateIncidentInHeroku(incident, successCallback:showSuccessMessage, failureCallback:showError)
    }
    
    func doneButtonPressed() {
        self.view.endEditing(true)
    }
    

    func showSuccessMessage() {
        dispatch_async(dispatch_get_main_queue(), {
            self.activityIndicator.stopAnimating()
            let alert : UIAlertView = UIAlertView(title: "Success", message: "Record updated", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        })
    }

    func showError(errorMessage:String) {
        dispatch_async(dispatch_get_main_queue(), {
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
            self.activityIndicator.stopAnimating()
            let alert : UIAlertView = UIAlertView(title: "Error", message: errorMessage, delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        })
    }
}