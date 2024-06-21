//
//  ViewController.swift
//  Redirect_to_Map
//
//  Created by E5000855 on 21/06/24.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var destinationAddress: UITextField!
    @IBOutlet weak var sourceAddress: UITextField!
    var locationManager: CLLocationManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        mapView.delegate = self
    }

    @IBAction func getDirection(_ sender: Any) {
        let appleMapsURL = "http://maps.apple.com/?saddr=\(sourceAddress.text ?? "")&daddr=\(destinationAddress.text ?? "")"
        print(appleMapsURL)
        if let url = URL(string: appleMapsURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            print("Unable to open Apple Maps.")
        }
    }

    @IBAction func showDirectionOnMapKit(_ sender: Any) {
        guard let sourceText = sourceAddress.text, !sourceText.isEmpty,
              let destinationText = destinationAddress.text, !destinationText.isEmpty else {
            print("Source and destination addresses are required")
            return
        }
        
        getLongAndLat(address: sourceText) { [weak self] sourceCoordinate, error in
            guard let self = self, let sourceCoordinate = sourceCoordinate else {
                print("Error fetching source coordinates: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.getLongAndLat(address: destinationText) { destinationCoordinate, error in
                guard let destinationCoordinate = destinationCoordinate else {
                    print("Error fetching destination coordinates: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.showRouteOnMap(pickupCoordinate: sourceCoordinate, destinationCoordinate: destinationCoordinate)
            }
        }
    }

    func getLongAndLat(address: String, completion: @escaping (CLLocationCoordinate2D?, Error?) -> Void) {
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            if let error = error {
                print(error.localizedDescription)
                completion(nil, error)
            } else if let placemark = placemarks?.first, let location = placemark.location {
                let result = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                completion(result, nil)
            } else {
                completion(nil, NSError(domain: "GeocodingErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "No valid location found"]))
            }
        }
    }

    func showRouteOnMap(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .automobile

        let directions = MKDirections(request: request)

        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else {
                print("Error calculating directions: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let route = unwrappedResponse.routes.first {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 80.0, left: 20.0, bottom: 100.0, right: 20.0), animated: true)
            } else {
                print("No routes found")
            }
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKGradientPolylineRenderer(overlay: overlay)
        renderer.setColors([
            UIColor(red: 0.02, green: 0.91, blue: 0.05, alpha: 1.00),
            UIColor(red: 1.00, green: 0.48, blue: 0.00, alpha: 1.00),
            UIColor(red: 1.00, green: 0.00, blue: 0.00, alpha: 1.00)], locations: [])
        renderer.lineCap = .round
        renderer.lineWidth = 3.0
        return renderer
    }
}



