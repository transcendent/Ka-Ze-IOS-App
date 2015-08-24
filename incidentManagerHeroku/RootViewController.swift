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

import UIKit
import MapKit


class RootViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate  {
    
    var incidentList = [Incident]()
    var selectedIncident:Incident?
    
    // represents the two subviews
    enum CurrentViewType {
        case Map
        case Table
    }

    var currentView:CurrentViewType? = nil
    
    var activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRectMake(0,0, 50, 50)) as UIActivityIndicatorView
    @IBOutlet weak var navgationControl: UINavigationItem!
    @IBOutlet weak var mapViewControl: MKMapView!
    @IBOutlet weak var changeViewSegmentControl: UISegmentedControl!
    @IBOutlet weak var tableViewControl: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // add the refresh button to the navigation bar
        var refreshButtonItem:UIBarButtonItem = UIBarButtonItem(title: "Refresh", style: .Plain, target: self, action: "loadIncidents")

        navgationControl.leftBarButtonItem = refreshButtonItem
        
        // setup the data source and delegate for the tableView
        tableViewControl.dataSource = self
        tableViewControl.delegate = self
        tableViewControl.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: "identifier")
        
        // default the current view to the Map
        setCurrentView(CurrentViewType.Map)
        
        // add the delegate to the map
        mapViewControl.delegate = self
        
    }
    
    //  load the data here to catch the return from the incidentDetailController
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // load the incidents from Heroku
        loadIncidents()
    }

    
    // switch the view
    @IBAction func segmentControlToggled(sender: AnyObject) {
        if (changeViewSegmentControl.selectedSegmentIndex == 0) {
            setCurrentView(CurrentViewType.Map)
        }
        else {
            setCurrentView(CurrentViewType.Table)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // loads the records from Heroku
    func loadIncidents() {
        // block input
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
        // put the spinner up
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        // load the current incidents from Heroku
        HerokuServices().getIncidentsFromHeroku(updateIncidentsCallback, failureCallback:showError)
    }
    
    // callback post update
    func updateIncidentsCallback(updatedIncidents:[Incident]) {
        dispatch_async(dispatch_get_main_queue(), {
            // clear all the current entries from the map
            self.mapViewControl.removeAnnotations(self.incidentList)
            // remove the current incident list with the updated version from Heroku
            self.incidentList = updatedIncidents
            // update the table and the map
            self.tableViewControl.reloadData()
            self.mapViewControl.addAnnotations(self.incidentList)
            // allow events again
            self.activityIndicator.stopAnimating()
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
        })
    }
    
    // sets the current view, hiding the appropriate controls
    func setCurrentView(newCurrentView:CurrentViewType) {
        // switch between our potential UI components
        if (newCurrentView == CurrentViewType.Map) {
            // hide the table, show the map
            mapViewControl.hidden = false
            tableViewControl.hidden = true
            currentView = CurrentViewType.Map
        }
        else if (newCurrentView == CurrentViewType.Table) {
            // and vice versa ...
            mapViewControl.hidden = true
            tableViewControl.hidden = false
            currentView = CurrentViewType.Table
        }
    }
    
    // opens up the selected incident in the detail view
    func openIncidentDetail() {
        self.performSegueWithIdentifier("openIncidentSegue", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "openIncidentSegue" {
            var viewController:IncidentDetailController = segue.destinationViewController as! IncidentDetailController
            viewController.incident = selectedIncident!
        }
    }

    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedIncident = incidentList[indexPath.row]
        openIncidentDetail()
    }

    
    
    // MARK: - UITableViewDataSource
    
    // only the single section in our design
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // likewise, just return the number of incidents that we pulled from Heroku
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return incidentList.count
    }
    
    // return the cell with the title that corresponds to the position in the incidents list
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableViewControl.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as? UITableViewCell
        if cell == nil {
            cell = UITableViewCell(style:UITableViewCellStyle.Default, reuseIdentifier: "cell")
        }
        var currentIncident:Incident = incidentList[indexPath.item]
        cell!.textLabel?.text = currentIncident.subject
        return cell!
    }
    
    
    // MARK: - MKMapViewDelegate
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if view.annotation.isKindOfClass(Incident) {
            selectedIncident = (view.annotation as! Incident)
            openIncidentDetail()
        }
    }
    
    func mapView(mapView: MKMapView!,viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView {
        
        var incident:Incident = annotation as! Incident
        let reuseId:String = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)   as? MKPinAnnotationView
        
        // if we got a new pinView, then set it up. Otherwise reuse the one that we got.
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: incident, reuseIdentifier: reuseId)
        } else {
            pinView!.annotation = annotation
        }
        
        // either way, set the pin colour and drop
        pinView!.animatesDrop = true
        
        if (incident.status == "Closed") {
            pinView!.pinColor = .Purple
        }
        else {
            pinView!.pinColor = .Red
        }
        return pinView!
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    func showError(errorMessage:String) {
        dispatch_async(dispatch_get_main_queue(), {
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
            self.activityIndicator.stopAnimating()
            var alert : UIAlertView = UIAlertView(title: "Error", message: errorMessage, delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        })
    }
    
}
