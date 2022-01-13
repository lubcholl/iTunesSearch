
import UIKit

class StoreItemContainerViewController: UIViewController, UISearchResultsUpdating {
    
    @IBOutlet var tableContainerView: UIView!
    @IBOutlet var collectionContainerView: UIView!
    
    let searchController = UISearchController()
    let storeItemController = StoreItemController()

    var tableViewDataSource: UITableViewDiffableDataSource<String, StoreItem>!
    var collectionViewDataSource: UICollectionViewDiffableDataSource<String, StoreItem>!
    
    //var items = [StoreItem]()
    var itemsSnapshot = NSDiffableDataSourceSnapshot<String, StoreItem>()
//    var itemsSnapshot: NSDiffableDataSourceSnapshot<String, StoreItem> {
//        var snapshot = NSDiffableDataSourceSnapshot<String, StoreItem>()
//        snapshot.appendSections(["Results"])
//        snapshot.appendItems(items)
//
//        return snapshot
//    }
    
    weak var collectionViewController: StoreItemCollectionViewController?
    
    func createSectionedSnapshot(from items: [StoreItem]) -> NSDiffableDataSourceSnapshot<String, StoreItem> {
        let movies = items.filter { $0.kind == "feature-movie" }
        let apps = items.filter { $0.kind == "software"}
        let music = items.filter { $0.kind == "song" || $0.kind == "album" }
        let books = items.filter { $0.kind == "ebook" }
        
        let grouped: [(SearchScope, [StoreItem])] = [
            (.movies, movies),
            (.apps, apps),
            (.music, music),
            (.books, books)
        ]
        var snapshot = NSDiffableDataSourceSnapshot<String, StoreItem>()
        grouped.forEach { (scope, items) in
            if items.count > 0 {
                snapshot.appendSections([scope.title])
                snapshot.appendItems(items, toSection: scope.title)
            }
        }
        
        return snapshot
    }
    
    
    //let queryOptions = SearchScope.allCases.map {$0.mediaTypes}
    var selectedSearchScope: SearchScope {
        let selectedIndex = searchController.searchBar.selectedScopeButtonIndex
        let searchScope = SearchScope.allCases[selectedIndex]
        return searchScope
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.automaticallyShowsSearchResultsController = true
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.scopeButtonTitles = SearchScope.allCases.map { $0.title }
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let tableViewController = segue.destination as? StoreItemListTableViewController {
            configureTableViewDataSource(tableViewController.tableView)
        }
        
        if let collectionViewController = segue.destination as? StoreItemCollectionViewController {
            self.collectionViewController = collectionViewController
            configureCollectionViewDataSource(collectionViewController.collectionView)
            collectionViewController.configureCollectionViewLayout(for: selectedSearchScope)
        }
    }
    
    func configureTableViewDataSource(_ tableView: UITableView) {
//        tableViewDataSource = UITableViewDiffableDataSource<String, StoreItem>(tableView: tableView, cellProvider: { (tableView, indexPath, item) -> UITableViewCell? in
//            let cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath) as! ItemTableViewCell
//            cell.configure(for: item, storeItemController: self.storeItemController)
//
//            return cell
//    })
      
        
        tableViewDataSource = StoreItemTableViewDiffableDataSource(tableView: tableView, storeItemController: storeItemController)
       
    }
    
    func configureCollectionViewDataSource(_ collectionView: UICollectionView) {
        collectionViewDataSource = .init(collectionView: collectionView, cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Item", for: indexPath) as! ItemCollectionViewCell
            cell.configure(for: item, storeItemController: self.storeItemController)
            
            return cell
        })
        
        collectionViewDataSource.supplementaryViewProvider = { collectionView, kind, indexPath -> UICollectionReusableView? in
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: "Header", withReuseIdentifier: StoreItemCollectionViewSectionHeader.reuseIdentifier, for: indexPath) as! StoreItemCollectionViewSectionHeader
            
            let title = self.itemsSnapshot.sectionIdentifiers[indexPath.section]
            headerView.setTitle(title)
            return headerView
        }
    
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(fetchMatchingItems), object: nil)
        perform(#selector(fetchMatchingItems), with: nil, afterDelay: 0.3)
    }
                
    @IBAction func switchContainerView(_ sender: UISegmentedControl) {
        tableContainerView.isHidden.toggle()
        collectionContainerView.isHidden.toggle()
    }
    
    
    @objc func fetchMatchingItems() {
        
        //self.items = []
        
        itemsSnapshot.deleteAllItems()
        
        // apply data source changes
        tableViewDataSource.apply(itemsSnapshot, animatingDifferences: true, completion: nil)
        collectionViewDataSource.apply(itemsSnapshot, animatingDifferences: true, completion: nil)
        
        let searchTerm = searchController.searchBar.text ?? ""
        //let mediaType = queryOptions[searchController.searchBar.selectedScopeButtonIndex]
        
        if !searchTerm.isEmpty {
            
            let searchScopes: [SearchScope]
            if selectedSearchScope == .all {
                searchScopes = [.movies, .books, .apps, .music]
            } else {
                searchScopes = [selectedSearchScope]
            }
            
            for searchScope in searchScopes {
            
                // set up query dictionary
                let query = [
                    "term": searchTerm,
                    "media": searchScope.mediaType,
                    "lang": "en_us",
                    "limit": "20"
                ]
                
                // use the item controller to fetch items
                storeItemController.fetchItems(matching: query) { (result) in
                    switch result {
                    case .success(let items):
                        // if successful, use the main queue to set self.items and reload the table view
                        DispatchQueue.main.async {
                            guard searchTerm == self.searchController.searchBar.text else {
                                return
                            }
                            
                            //self.items = items
                            // apply data source changes
                            self.handleFetchedItems(items)
                        }
                    case .failure(let error):
                        // otherwise, print an error to the console
                        print(error)
                    }
                }
            }
        }
    }
    
    func handleFetchedItems(_ items: [StoreItem]) {
        
        let currentSnapshotItems = itemsSnapshot.itemIdentifiers
//        print(currentSnapshotItems)
//        var updatedSnapshot = NSDiffableDataSourceSnapshot<String, StoreItem>()
//        updatedSnapshot.appendSections(["Results"])
//        updatedSnapshot.appendItems(currentSnapshotItems + items)
        itemsSnapshot = createSectionedSnapshot(from: currentSnapshotItems + items)
        
        tableViewDataSource.apply(itemsSnapshot, animatingDifferences: true, completion: nil)
        collectionViewDataSource.apply(itemsSnapshot, animatingDifferences: true, completion: nil)
        
        collectionViewController?.configureCollectionViewLayout(for: selectedSearchScope)
    }
    
}
