//
//  MapMarkerWindow.swift
//  GoogleMapsDemo
//
//  Created by mengjiao on 1/5/21.
//

import UIKit
import GoogleMaps

protocol MapMarkerDelegate: class {
    // add delegate methods if nessasry
}

//customize view for infor window
class MapMarkerWindow: UIView {

    @IBOutlet weak var infoLabel: UILabel!

    weak var delegate: MapMarkerDelegate?
    
    //datas for infowindow
    var spotData: NSDictionary?
    
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "MapMarkerWindowView", bundle: nil).instantiate(withOwner: self, options: nil).first as! UIView
    }
}


