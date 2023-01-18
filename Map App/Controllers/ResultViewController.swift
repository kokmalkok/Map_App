//
//  ResultViewController.swift
//  Map App
//
//  Created by Константин Малков on 17.11.2022.
//

import UIKit
import MapKit

class ResultViewController: UIViewController {
    
    static let identifier = "ResultViewController"
    var matchingItems: [MKMapItem] = []
    var mapView: MKMapView?
    var testValueForSecondTable: [String] = []
    var lastRequest: [LastChoosenRequest] = []
    private let geocoder = CLGeocoder()
    private let coreData = SearchHistoryStack.instance
    
    var handleMapSearchDelegate: HandleMapSearch? = nil

    let imageDictionary = ["Airport":UIImage(systemName: "airplane.arrival"),
                           "Food places":UIImage(systemName: "fork.knife"),
                           "Market":UIImage(systemName: "basket"),
                           "Pharmacy":UIImage(systemName: "cross.case"),
                           "Hotels":UIImage(systemName: "bed.double"),
                           "Petrol Station":UIImage(systemName: "fuelpump"),
                           "Cinema":UIImage(systemName: "popcorn"),
                           "Fitness":UIImage(systemName: "dumbbell")
    ]
    
    let table: UITableView = {
       let table = UITableView()
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cellRequest")
        return table
    }()
    
    private var categoryCollectionView: UICollectionView!
    
    
    
    private let previosRequests = UITableView(frame: .zero, style: .plain)
    
    private var resultSearchController: UISearchController = {
        var search = UISearchController()
        search.searchBar.searchBarStyle = .minimal
        search.searchBar.placeholder = "Print Request"
        search.searchBar.backgroundColor = .systemBackground
        search.searchBar.returnKeyType = .search
        search.scopeBarActivation = .onTextEntry
        search.showsSearchResultsController = true
        search.automaticallyShowsCancelButton = true
        search.hidesNavigationBarDuringPresentation = true
        return search
    }()
    
    private let closeButton: UIButton = {
       let button = UIButton()
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .black
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: #selector(didTapDismiss), for: .touchUpInside)
        button.backgroundColor = .systemGray5
        return button
    }()
    
    private let searchImage: UIImageView = {
       let image = UIImageView()
        image.image = UIImage(systemName: "magnifyingglass")
        image.tintColor = .darkGray
        image.sizeToFit()
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    private let segmentalButtons: UISegmentedControl = {
       let button = UISegmentedControl(items: ["Categories","History"])
        button.tintColor = .systemBackground
        button.selectedSegmentIndex = 0
        button.backgroundColor = .systemGray5
        button.addTarget(self, action: #selector(didTapToChangeSegment), for: .valueChanged)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupNavigationAndView()
        
        
        
        
        newSetupSearchController()
        setupTable()
        setupSearchBarConstraints()
        
 
    }

    
    override func viewDidLayoutSubviews(){
        let safeArea = view.safeAreaInsets.top
        resultSearchController.searchBar.frame = CGRect(x: 45, y: safeArea+10, width: view.frame.size.width-100, height: 50)
        closeButton.frame = CGRect(x: view.frame.size.width-50, y: safeArea+15, width: 40, height: 40)
        closeButton.layer.cornerRadius = 0.5 * closeButton.bounds.width
        searchImage.frame = CGRect(x: 10, y: safeArea+15, width: 40, height: 40)
        searchImage.layer.cornerRadius = 0.5 * searchImage.bounds.width
        segmentalButtons.frame = CGRect(x: 55, y: safeArea+65, width: view.frame.size.width-110, height: 40)
        table.frame = CGRect(x: 0, y: safeArea+110, width: view.frame.size.width, height: view.frame.size.height-80)
        categoryCollectionView.frame = CGRect(x: 0, y: safeArea+110, width: view.frame.size.width, height: view.frame.size.height-100)
        

    }
    @objc private func didTapDismiss(){
        self.dismiss(animated: true)
    }
    
    @objc private func didTapToChangeSegment(){
        //для перехода от одного вью к другому
        switch segmentalButtons.selectedSegmentIndex {
        case 0:
            resultSearchController.searchBar.isHidden = false
            categoryCollectionView.isHidden = false
            segmentalButtons.frame = CGRect(x: 55, y: view.safeAreaInsets.top+65, width: view.frame.size.width-110, height: 40)
            table.reloadData()
            matchingItems = []
        default:
            table.reloadData()
            resultSearchController.searchBar.text = ""
            matchingItems = []
            resultSearchController.searchBar.isHidden = true
            categoryCollectionView.isHidden = true
            segmentalButtons.frame = CGRect(x: 55, y: view.safeAreaInsets.top+15, width: view.frame.size.width-110, height: 40)

        }
    }
    
    private func setupSearchBarConstraints(){
        let bar = resultSearchController.searchBar
        bar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: view.topAnchor,constant: 10),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor,constant: -50),
            bar.heightAnchor.constraint(equalToConstant: 55),
            bar.widthAnchor.constraint(equalToConstant: view.frame.size.width-100)
        ])
    }
    
    private func setupCollectionView(){
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        layout.itemSize = CGSizeMake(80, 90)
        layout.sectionInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        categoryCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        categoryCollectionView.dataSource = self
        categoryCollectionView.delegate = self
        categoryCollectionView.register(FavouriteCollectionViewCell.self, forCellWithReuseIdentifier: FavouriteCollectionViewCell.identifier)
        categoryCollectionView.backgroundColor = .systemBackground
        categoryCollectionView.isUserInteractionEnabled = true
        categoryCollectionView.contentInsetAdjustmentBehavior = .automatic
    }
    
    func newSetupSearchController(){
        resultSearchController.searchResultsUpdater = self
        definesPresentationContext = true
        resultSearchController.searchBar.delegate = self
    }
    
    func setupTable(){
        table.delegate = self
        table.dataSource = self
        table.backgroundColor = .systemBackground
        table.contentInsetAdjustmentBehavior = .always

        coreData.loadHistoryData()
    }
    
    func setupNavigationAndView(){
        view.addSubview(table)
        view.addSubview(resultSearchController.searchBar)
        view.addSubview(closeButton)
        view.addSubview(searchImage)
        view.addSubview(segmentalButtons)
        view.addSubview(categoryCollectionView)
        view.backgroundColor = .systemBackground
        navigationController?.navigationItem.largeTitleDisplayMode = .never
        view.inputViewController?.edgesForExtendedLayout = .all
    }
    
    //не работает тк неудачно конвертирует координаты в placemark
    //необходимо отредактировать функцию!!!
    func convertLocInPlacemark(location:CLLocationCoordinate2D, completion: @escaping(CLPlacemark)-> Void) {
        let coordinate = CLLocation(latitude: location.latitude, longitude: location.longitude)
//        var returnPlacemark: CLPlacemark?
        geocoder.reverseGeocodeLocation(coordinate) { placemark, error in
            guard let placemarkT = placemark?.first, error != nil else {
                return
            }
            completion(placemarkT)
            print(placemark?.first?.name)
//            returnPlacemark = placemarkT
        }
//        return returnPlacemark!
        /////
    }
    
    func alternativeParseData(customMark: MKPlacemark) -> String {
        
        let addressLine = "\(customMark.thoroughfare ?? ""), \(customMark.locality ?? ""), \(customMark.subLocality ?? ""), \(customMark.administrativeArea ?? ""), \(customMark.postalCode ?? ""), \(customMark.country ?? "")"
        return addressLine
    }
}

extension ResultViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let mapView = mapView, let text = searchController.searchBar.text else {
            return
        }
        if text != "" {
            categoryCollectionView.isHidden = true
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = text
            request.region = mapView.region
            let search = MKLocalSearch(request: request)
            search.start { response, _ in
                guard let response = response else {
                    return
                }
                self.matchingItems = response.mapItems
                self.table.reloadData()
            }
        }
        
    }
    
    
    
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text ,!text.isEmpty {
            searchBar.text = ""
            matchingItems = []
            table.reloadData()
            categoryCollectionView.isHidden = false
            table.isHidden = true
        }
    }
    
//    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        resultSearchController.searchBar.frame = CGRect(x: 10, y: view.safeAreaInsets.top+60, width: view.frame.size.width-60, height: 40)
//        resultSearchController.isActive = false
//        if let text = searchBar.text {
//
//        }
//    }
    
}

extension ResultViewController: UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageDictionary.keys.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FavouriteCollectionViewCell.identifier, for: indexPath) as! FavouriteCollectionViewCell
        let keys = Array(imageDictionary.keys)[indexPath.row]
        let value = Array(imageDictionary.values)[indexPath.row]
        
        cell.configureCell(title: keys, image: value!)
        return cell
    }
    
    
}

extension ResultViewController:  UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.table && segmentalButtons.selectedSegmentIndex == 0{
            return matchingItems.count
        } else {
//            return lastRequest.count
            return coreData.historyVault.count
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cellRequest",for: indexPath)
        cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellRequest")
        if segmentalButtons.selectedSegmentIndex == 0 {
            let selectedItems = matchingItems[indexPath.row].placemark
            cell.textLabel?.text = selectedItems.name
            cell.detailTextLabel?.text = alternativeParseData(customMark: selectedItems)
        } else {
//            let request = lastRequest[indexPath.row]
//            let placemark = request.placemark
//            cell.textLabel?.text = request.titleRequest
//            cell.detailTextLabel?.text = alternativeParseData(customMark: placemark)
            let data = coreData.historyVault[indexPath.row]
            cell.textLabel?.text = data.nameCategory
            let location = CLLocationCoordinate2D(latitude: data.langitude, longitude: data.longitude)
            let _: () = convertLocInPlacemark(location: location) { placemark in
                let convert = MKPlacemark(placemark: placemark)
                cell.detailTextLabel?.text = self.alternativeParseData(customMark: convert)
                
            }
//            let convert = MKPlacemark(placemark: placemark)
//            cell.detailTextLabel?.text = alternativeParseData(customMark: convert)
        }
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if segmentalButtons.selectedSegmentIndex == 0 {
            let selectedItem = matchingItems[indexPath.row].placemark
            handleMapSearchDelegate?.dropPin(placemark: selectedItem,requestName: selectedItem.name)
//            if let name = selectedItem.name {
//                lastRequest.append(LastChoosenRequest(placemark: selectedItem, titleRequest: name))
//            }
            if let name = selectedItem.name{
                let coordinate = selectedItem.coordinate
                coreData.saveHistoryDataElement(name: name, lan: coordinate.latitude, lon: coordinate.longitude)
                self.table.reloadData()
            }
            self.dismiss(animated: true)
        } else {
            let data = coreData.historyVault[indexPath.row]
            let name = data.nameCategory
            let location = CLLocationCoordinate2D(latitude: data.langitude, longitude: data.longitude)
            convertLocInPlacemark(location: location) { mark in
                let convertMark = MKPlacemark(placemark: mark)
                self.handleMapSearchDelegate?.dropPin(placemark: convertMark, requestName: name)
            }
            self.dismiss(animated: true)
            
            
//            let selectedItem = lastRequest[indexPath.row].placemark
//            let name = lastRequest[indexPath.row].titleRequest
//            handleMapSearchDelegate?.dropPin(placemark: selectedItem, requestName: name)
            
        }
    }
}





