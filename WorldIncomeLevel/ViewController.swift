//
//  ViewController.swift
//  WorldIncomeLevel
//
//  Created by User01 on 30/06/17.
//  Copyright © 2017 User01. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var areaListButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    
    var contentController: UITableViewController!
    var areaListTable: UITableView!
    var selectedItemIndex: Int!
    
    var regionNames = ["Africa", "East Asia and the Pacific", "Central Europe and the Baltics", "Europe and Central Asia", "Latin America and the Caribbean", "Middle East and North Africa", "South Asia", "European Union", "North America", "North Africa", "South Asia"]
    var regionCodes = ["AFR", "CEA","CEB","CEU","CLA","CME","CSA","EUU","NAC","NAF","SAS"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        contentController = UITableViewController()
        areaListTable = UITableView()
        areaListTable.dataSource = self
        areaListTable.delegate = self
        contentController.tableView = areaListTable
        selectedItemIndex = -1
        mapView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showAreaList(_ sender: Any) {
        contentController.modalPresentationStyle = UIModalPresentationStyle.popover
        let popOverPC: UIPopoverPresentationController = contentController.popoverPresentationController!
        popOverPC.barButtonItem = areaListButton
        popOverPC.permittedArrowDirections = UIPopoverArrowDirection.any
        popOverPC.delegate = self
        present(contentController, animated: true, completion: nil)
    }
    
    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier")
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.value1, reuseIdentifier: "cellIdentifier")
            cell.textLabel?.text = regionNames[indexPath.row]
        }
        cell.accessoryType = UITableViewCellAccessoryType.none
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return regionNames.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell:UITableViewCell = tableView.cellForRow(at: indexPath)!
        selectedCell.accessoryType = UITableViewCellAccessoryType.checkmark
        selectedItemIndex = indexPath.row
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let deselectedCell:UITableViewCell = tableView.cellForRow(at: indexPath)!
        deselectedCell.accessoryType = UITableViewCellAccessoryType.none
    }
    
    // MARK: UIPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .fullScreen
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        let navController: UINavigationController = UINavigationController(rootViewController: controller.presentedViewController)
        controller.presentedViewController.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(ViewController.done))
        areaListTable.reloadData()
        selectedItemIndex = -1
        return navController
    }
    
    func done() {
        presentedViewController?.dismiss(animated: true, completion: nil)
        mapSearch()
    }
    
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        areaListTable.reloadData()
        selectedItemIndex = -1
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        mapSearch()
    }
    
    func mapSearch() {
        if selectedItemIndex == -1 {
            return
        }
        let url:NSURL = NSURL(string: "http://api.worldbank.org/country?per_page=100&ampregion=\(regionCodes[selectedItemIndex])&format=json")!
        let task = URLSession.shared.dataTask(with: url as URL) { (data:Data?, response: URLResponse?, error:Error?) -> Void in
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSArray
                let dataArray = json.object(at: 1) as! NSArray
                DispatchQueue.main.async {
                    self.displayRegionalIncomeLevel(data: dataArray as [AnyObject])
                }
            } catch {
                print("Some error occurred")
            }
        }
        task.resume()
    }
    
    func displayRegionalIncomeLevel(data:[AnyObject]) {
        if data.count == 0 {
            return
        }
        let regionLongitude = data[1]["longitude"]
        let regionLatitude = data[1]["latitude"]
        let center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude:(regionLatitude as! NSString).doubleValue, longitude:(regionLongitude as! NSString).doubleValue)
        let region: MKCoordinateRegion = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta:10, longitudeDelta:10))
        self.mapView.setRegion(region, animated: true)
        
        var lon:Double!
        var lat:Double!
        var annotationView:MKPinAnnotationView!
        var pointAnnotation:CustomPointAnnotation!
        
        for item in data {
            let obj = item as! Dictionary<String, AnyObject>
            lon = obj["longitude"]!.doubleValue
            lat = obj["latitude"]!.doubleValue
            
            pointAnnotation = CustomPointAnnotation()
            let incomeLevel:Dictionary<String,AnyObject> = obj["incomeLevel"] as! Dictionary<String,AnyObject>
            let incomeLevelValue = (incomeLevel["value"] as! String)
            if incomeLevelValue == "High income: OECD" || incomeLevelValue == "High income: nonOECD" {
                pointAnnotation.pinCustomImageName = "High income"
            } else {
                pointAnnotation.pinCustomImageName = (incomeLevel["value"] as! String)
            }
            
        }
        
    }
}

