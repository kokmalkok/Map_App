//
//  MapViewController.swift
//  Map App
//
//  Created by Константин Малков on 30.08.2022.
//задачи:
//несколько городов в списке
//камера при создании маршрута
//попробовать поиск по улице(но это не точно)
//добавление в избранное конкретную локацию
//добавить боковое меню для удобства навигации


//this is main class which show user location, set and show users custom direction from A point to B point, else setups visual view with or without some elements on user screen. And the main is searching for city (for streets and etc is in progress development)
import UIKit
import MapKit
import CoreLocationUI
import SPAlert

protocol HandleMapSearch {
    func dropPin(placemark: MKPlacemark,requestName: String?)
}

class MapViewController: UIViewController {

    let mapView = MKMapView()
    let locationManager = CLLocationManager()
    let annotationCustom = MKPointAnnotation()
    
    
    private let geocoder = CLGeocoder()
    var selectedCoordination: CLLocationCoordinate2D?
    var previosLocation: CLLocation?
    var directionsArray: [MKDirections] = []
    var savedLocationToShowDirection: CLLocationCoordinate2D?
    var coordinateSpanValue = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    var currentLocation = CLLocationCoordinate2D()
    
    let favouriteButton: UIButton = {
        let button = UIButton()
         button.layer.cornerRadius = 8
         button.backgroundColor = .secondarySystemFill
         button.setImage(UIImage(systemName: "bookmark",
                                 withConfiguration: UIImage.SymbolConfiguration(
                                 pointSize: 32,
                                 weight: .medium)),
                                 for: .normal)
         button.tintColor = .black
         return button
     }()
    
    let locationButton: CLLocationButton = {
        let locationButton = CLLocationButton()
        locationButton.icon = .arrowOutline
        locationButton.isHighlighted = true
        locationButton.cornerRadius = 20
        locationButton.backgroundColor = .black
        return locationButton
    }()
    
    let clearMapButton: UIButton = {
       let button = UIButton()
        button.setImage(UIImage(systemName: "xmark.circle.fill",
                                withConfiguration: UIImage.SymbolConfiguration(
                                    pointSize: 32,
                                    weight: .medium)),
                        for: .normal)
        button.layer.cornerRadius = 8
        button.backgroundColor = .systemBackground
        button.tintColor = .black
        return button
    }()
    
    let stepper: UIStepper = {
       let stepper = UIStepper()
        stepper.minimumValue = 0.05
        stepper.maximumValue = 0.45
        stepper.stepValue = 0.2
        stepper.value = 0.05
        stepper.addTarget(self, action: #selector(updateStepper), for: .valueChanged)
        return stepper
    }()
    
    var searchController: UISearchController = {
        let search = UISearchController()
        search.searchBar.searchBarStyle = .prominent
        search.searchBar.placeholder = "Print Request"
        search.searchBar.backgroundColor = .systemBackground
        search.showsSearchResultsController = true
        search.automaticallyShowsCancelButton = true
        search.hidesNavigationBarDuringPresentation = false
        search.searchBar.sizeToFit()
        return search
    }()
    //MARK: - Main View Loadings Methods
    override func viewDidAppear(_ animated: Bool) {
        setupDelegates()
        super.viewDidAppear(animated)
        //функция добавления аннотации и открытия вью при выборе строки из FavouriteTVC
        if let location = savedLocationToShowDirection {
            setChoosenLocation(coordinates: location,requestName: "")
            let vc = PlotInfoViewController()
            vc.coordinatesForPlotInfo = location
            vc.delegate = self
            vc.modalPresentationStyle = .pageSheet
            vc.sheetPresentationController?.detents = [.medium(),.large()]
            vc.sheetPresentationController?.prefersGrabberVisible = true
            self.present(vc, animated: true)
            savedLocationToShowDirection = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startTrackingUserLocation()
        setupWeather()
    }
    //key func for collecting all funcs for working and showing first necessary information
    private func startTrackingUserLocation(){
        setupSubviews()
        setupLocationManager()
        setupViewsTargetsAndDelegates()
        setupSearchAndTable()
        setupDelegates()
        previosLocation = getCenterLocation(for: mapView) //collect last data with latitude and longitude
    }

    //MARK: - Layout setup
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let navVC = navigationController?.navigationBar.frame.size.height else { return }
        mapView.frame = view.bounds
        locationButton.frame = CGRect(x: view.frame.size.width-40, y:view.safeAreaInsets.top+navVC+locationButton.frame.size.height+40 , width: 40, height: 40)
        clearMapButton.frame = CGRect(x: view.frame.size.width-40, y: view.safeAreaInsets.top+navVC+40+locationButton.frame.size.height+40, width: 40, height: 40)
        clearMapButton.layer.cornerRadius = 0.5 * clearMapButton.bounds.size.width
        stepper.frame = CGRect(x: view.frame.size.width-120, y: view.frame.size.height-100, width: 100, height: 50)
    }
    //MARK: - Objc methods
    //func for getting user location when user press on location button
    @objc private func didTapLocation(){
        setupLocationManager()
    }
    //method for stepper
    @objc private func updateStepper(_ sender: UIStepper){
        print(sender.value)
        coordinateSpanValue = MKCoordinateSpan(latitudeDelta: sender.value, longitudeDelta: sender.value)
        let coordinate = currentLocation
        let region = MKCoordinateRegion(center: coordinate, span: coordinateSpanValue)
        self.mapView.setRegion(region, animated: true)
    }
    //segue to Favourite View Contr
    @objc private func didTapToFavourite(){
        let vc = FavoriteTableViewController()
        vc.delegate = self
        let secVC = PlotInfoViewController()
        secVC.delegate = self
        let navVc = UINavigationController(rootViewController: vc)
        navVc.modalPresentationStyle = .fullScreen
        present(navVc, animated: true)
    }
    
    @objc private func didTapSearch(){
        let vc = ResultViewController()
//        let nav = UINavigationController(rootViewController: vc)
        vc.mapView = mapView
        vc.handleMapSearchDelegate = self
        
        vc.modalPresentationStyle = .pageSheet
        vc.sheetPresentationController?.detents = [.large(),.medium()]
        vc.sheetPresentationController?.prefersGrabberVisible = true
        present(vc, animated: true)
    }
    
    //add annotation on map and open detail view
    @objc func addAnnotationOnLongPress(gesture: UILongPressGestureRecognizer){
        print("pressed")
        if gesture.state == .ended{
            mapView.removeAnnotation(annotationCustom)
            mapView.removeAnnotations(mapView.annotations)
            if streetName(location: gesture) != nil{
            }
        }
    }
    //func of cleaning view from directions and pins
    @objc private func didTapClearDirection(){
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeAnnotation(annotationCustom)
    }
    //подумать нужна или нет
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let point = touch.location(in: mapView)
            let location = mapView.convert(point, toCoordinateFrom: mapView)
            selectedCoordination = location
        }
    }
    
    //function of lift up view
    @objc func keyboardWillShow(notification: NSNotification){
        if let keyboardsize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardsize.height
            }
        }
    }
    //func of lift down view after using search bar
    @objc func keyboardWillHide(notification: NSNotification){
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    //MARK: - setup visual elements
    //weather test
    func setupWeather(){
        //импортировать кит с погодой
    }
    //проверить нужна ли эта функция ???
    func setupSearchAndTable(){
        let tableDelegate = storyboard!.instantiateViewController(withIdentifier: "ResultViewController") as! ResultViewController
        searchController = UISearchController(searchResultsController: tableDelegate)
        searchController.searchResultsUpdater = tableDelegate
        tableDelegate.mapView = mapView
        tableDelegate.handleMapSearchDelegate = self
        definesPresentationContext = true
        //КОНТРОЛЛЕР убран из вью!!!!
//        navigationItem.searchController = searchController
        //
    }
    func setupSubviews(){
        view.addSubview(mapView)
        view.addSubview(locationButton)
        view.addSubview(clearMapButton)
        view.addSubview(stepper)
    }
    //add views in subview,targets and delegates
    func setupViewsTargetsAndDelegates(){
        //targets
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationOnLongPress(gesture:)))
        locationButton.addTarget(self, action: #selector(didTapLocation), for: .touchUpInside)
        clearMapButton.addTarget(self, action: #selector(didTapClearDirection), for: .touchUpInside)
        //below two funcs which setup showing and hiding keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        //nav item set up
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "bookmark.fill"), landscapeImagePhone: nil, style: .plain, target: self, action: #selector(didTapToFavourite))
        navigationItem.rightBarButtonItem?.tintColor = .black
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass.circle.fill"), style: .done, target: self, action: #selector(didTapSearch))
        navigationItem.leftBarButtonItem?.tintColor = .black
        
        //delegates and secondary setups
        longGesture.minimumPressDuration = 0.5
        definesPresentationContext = true
        
        mapView.showsCompass = false
        mapView.userTrackingMode = .followWithHeading
        mapView.addGestureRecognizer(longGesture)
        mapView.selectableMapFeatures = [.pointsOfInterest]
        let mapConfig = MKStandardMapConfiguration()
        mapConfig.pointOfInterestFilter = .includingAll
        mapConfig.showsTraffic = true
        mapView.preferredConfiguration = mapConfig
    }
    //location manager settings
    func setupLocationManager(){
        locationManager.startUpdatingLocation()
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        if let location = locationManager.location?.coordinate {
            let center = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: center, span: span)
            self.mapView.setRegion(region, animated: true)
        }
    }
    //date converter and returnin last current time
    private func dateConverter() -> String{
        let date = Date()
        let format = DateFormatter()
        format.dateFormat = "HH:mm:ss"
        format.timeStyle = .medium
        format.dateStyle = .long
        format.timeZone = TimeZone(abbreviation: "UTC")
        let stringFormat = format.string(from: date)
        return stringFormat
    }
    
    private func setupDelegates(){
        let vc = PlotInfoViewController()
        vc.delegate = self
        let sec = FavoriteTableViewController()
        sec.delegate = self
        locationManager.delegate = self
        mapView.delegate = self
        searchController.delegate = self
    }
    //MARK: - Setups for displaying direction, converter methods and getters of address
    public func setChoosenLocation(coordinates: CLLocationCoordinate2D,requestName: String?) {
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        mapView.removeAnnotation(annotationCustom)
        mapView.removeAnnotations(mapView.annotations)
        geocoder.reverseGeocodeLocation(location) { placemark, error in
            guard let placemark = placemark?.first else { return }
            let streetName = placemark.thoroughfare ?? ""
            let appartmentNumber = placemark.subThoroughfare ?? ""
            let city = placemark.administrativeArea ?? ""
            let country = placemark.country ?? ""
            let point = placemark.areasOfInterest?.first ?? "Untitled"
            DispatchQueue.main.async {
                if point == "" {
                    self.annotationCustom.title = "\(streetName), дом \(appartmentNumber)"
                    self.annotationCustom.subtitle = "Г. \(city), \(country)"
                    self.annotationCustom.coordinate = coordinates
                    self.mapView.setCenter(coordinates, animated: true)
                    
                    self.mapView.setRegion(MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)), animated: true)
                    self.mapView.addAnnotation(self.annotationCustom)
                } else {
                    self.annotationCustom.title = point
                    self.annotationCustom.subtitle = "\(streetName), дом \(appartmentNumber)\nГ. \(city), \(country)"
                    self.annotationCustom.coordinate = coordinates
                    self.mapView.setRegion(MKCoordinateRegion(center: coordinates, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)), animated: true)
                    self.mapView.addAnnotation(self.annotationCustom)
                }
            }
        }
    }
    //func for getting user's location data
    func getCenterLocation(for mapView: MKMapView) -> CLLocation {
           let latitude = mapView.centerCoordinate.latitude
           let longitude = mapView.centerCoordinate.longitude
           return CLLocation(latitude: latitude, longitude: longitude)
    }
    //func for gesture location and for output locations data
    func gestureLocation(for gesture: UILongPressGestureRecognizer) -> CLLocationCoordinate2D? {
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        annotationCustom.coordinate = coordinate
        self.mapView.addAnnotation(annotationCustom)
        return coordinate
    }
    //func for  getting street name and number of buildings
    func streetName(location gesture: UILongPressGestureRecognizer) -> CLPlacemark? {
        let center = gestureLocation(for: gesture)
        var returnPlacemark: CLPlacemark?
        guard let center = center else {
            return nil
        }
        let locationData = CLLocation(latitude: center.latitude, longitude: center.longitude)
        geocoder.reverseGeocodeLocation(locationData) { [weak self] placemark, error in
            guard let placemark = placemark?.first else {
                return
            }
            guard let self = self else {
                return
            }
            returnPlacemark = placemark
            let street = placemark.thoroughfare ?? ""
            let streetNum = placemark.subThoroughfare ?? ""
            DispatchQueue.main.async {
                let vc = PlotInfoViewController()
                vc.coordinatesForPlotInfo = center
                vc.delegate = self
                vc.modalPresentationStyle = .pageSheet
                vc.sheetPresentationController?.detents = [.medium(),.large()]
                vc.sheetPresentationController?.prefersGrabberVisible = true
                self.present(vc, animated: true)
                self.annotationCustom.title = "\(street), \(streetNum)"
            }
        }
        return returnPlacemark
    }
    //MARK: - Direction Settings
    //func for starting showing direction. Func input user location and return polyline on map
    func getDirection(locationDirection: CLLocationCoordinate2D?){
        guard let checkLoc = locationDirection else {
            return
        }
        let request = createDirectionRequest(from: checkLoc)
        let directions = MKDirections(request: request)
        resetMap(withNew: directions)
        directions.calculate { [unowned self] response, error in
            //output alert if error
            guard let response = response, error == nil else {
                return
            }
            for route in response.routes {
                _ = route.steps
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    //main setups for direction display. Input user location and output result of request by start and end location
    func createDirectionRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate = coordinate //endpoint coordinates
        let startingLocation      = MKPlacemark(coordinate: locationManager.location!.coordinate)//checking for active user location
        let destination           = MKPlacemark(coordinate: destinationCoordinate) //checking for having endpoint coordinates
        let request               = MKDirections.Request()
        request.source                       = MKMapItem(placemark: startingLocation)
        request.destination                  = MKMapItem(placemark: destination)
        request.transportType                = .walking
        request.requestsAlternateRoutes     = false
        
        annotationCustom.coordinate = destinationCoordinate
        return request
    }
    //func for clean direction
    func resetMap(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map { $0.cancel() }
    }
   
    //MARK: - Error debagging and if statements

    //check for error
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            setupLocationManager()
            previosLocation = getCenterLocation(for: mapView)
        case .authorizedAlways:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            break
            //show alert
        case .denied:
            break
            //show alert
        @unknown default:
            fatalError()
        }
    }
}
//MARK: - Extensions for Delegates
extension MapViewController: FavouritePlaceDelegate{
    func passCoordinates(coordinates: CLLocationCoordinate2D) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeAnnotation(annotationCustom)
        savedLocationToShowDirection = coordinates
    }
}

extension MapViewController:  PlotInfoDelegate {
    func deleteAnnotations(boolean: Bool) {
        if boolean == true {
            if let search = searchController.searchBar.text, !search.isEmpty {
                mapView.removeAnnotation(annotationCustom)
                mapView.removeAnnotations(mapView.annotations)
                searchController.searchBar.text = ""
            }
            mapView.removeAnnotation(annotationCustom)
            mapView.removeAnnotations(mapView.annotations)
            
        }
    }
    
    func passAddressNavigation(location: CLLocationCoordinate2D) {
        
        let locationData = CLLocation(latitude: location.latitude, longitude: location.longitude)
        geocoder.reverseGeocodeLocation(locationData) { [weak self] placemark, error in
            guard let placemark = placemark?.first else {
                return
            }
            guard let self = self else {
                return
            }
            let streetName = placemark.thoroughfare ?? ""
            let streetNumber = placemark.subThoroughfare ?? ""
            let city = placemark.administrativeArea ?? ""
            let country = placemark.country ?? ""
            let areaInterests = placemark.areasOfInterest ?? []
            DispatchQueue.main.async {
                    if areaInterests == [] {
                        self.annotationCustom.coordinate = location
                        self.annotationCustom.title = "\(streetName), дом \(streetNumber)"
                        self.annotationCustom.subtitle = "\(city), \(country)"
                        self.mapView.addAnnotation(self.annotationCustom)
                        self.getDirection(locationDirection: location)
                    } else if areaInterests != [] {
                        self.annotationCustom.coordinate = location
                        self.annotationCustom.title = areaInterests.first
                        self.annotationCustom.subtitle = "г. \(city) "
                        self.mapView.addAnnotation(self.annotationCustom)
                        self.getDirection(locationDirection: location)
                }
            }
        }
    }
}


extension MapViewController: HandleMapSearch {
    func dropPin(placemark: MKPlacemark,requestName: String?) {
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeAnnotation(annotationCustom)
        annotationCustom.coordinate = placemark.coordinate
        annotationCustom.title = placemark.name
        if let city = placemark.locality, let street = placemark.thoroughfare, let appartment = placemark.subThoroughfare {
            annotationCustom.subtitle = "\(city), \(street), дом \(appartment)"
        }
        mapView.addAnnotation(annotationCustom)
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        let vc = PlotInfoViewController()
        vc.pointOfInterest = requestName ?? placemark.areasOfInterest?.first
        vc.coordinatesForPlotInfo = placemark.coordinate
        vc.delegate = self
        vc.modalPresentationStyle = .pageSheet
        vc.sheetPresentationController?.detents = [.medium(),.large()]
        vc.sheetPresentationController?.prefersGrabberVisible = true
        present(vc, animated: true)
    }
}
//MARK: - Extensions Data Source
extension MapViewController: UISearchBarDelegate, UISearchControllerDelegate{
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        let nav = UINavigationController(rootViewController: ResultViewController())
        self.present(nav,animated: true)
    }
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locations = locations.first else {
            return
        }
        let center = CLLocationCoordinate2D(latitude: locations.coordinate.latitude, longitude: locations.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: center, span: span)
        self.mapView.setRegion(region, animated: true)
        self.locationManager.stopUpdatingLocation()
        self.currentLocation = center
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "marker")
        annotationView.markerTintColor = .black
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//        if view.annotation != nil {
//            mapView.removeAnnotation(annotationCustom)
//        }
        let vc = PlotInfoViewController()
        vc.pointOfInterest = view.annotation?.title ?? "No title"
        vc.coordinatesForPlotInfo = view.annotation?.coordinate
        vc.delegate = self
        vc.modalPresentationStyle = .pageSheet
        vc.sheetPresentationController?.detents = [.medium(),.large()]
        vc.sheetPresentationController?.prefersGrabberVisible = true
        present(vc, animated: true)
        
    }
    //polyline setups
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .systemIndigo
        return renderer
    }
}
