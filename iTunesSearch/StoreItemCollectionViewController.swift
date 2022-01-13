
import UIKit

class StoreItemCollectionViewController: UICollectionViewController {
    
    //@IBOutlet var flowLayout: UICollectionViewFlowLayout!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.register(StoreItemCollectionViewSectionHeader.self, forSupplementaryViewOfKind: "Header", withReuseIdentifier: StoreItemCollectionViewSectionHeader.reuseIdentifier)
        
        let availableWidth = view.frame.width
        let itemWidth = (availableWidth - (8*4)) / 3
        let itemSize = CGSize(width: itemWidth, height: itemWidth * 2)
        let minimumInterItemSpacing: CGFloat = 8
        let minimumLineSpacing: CGFloat = 12

//        flowLayout.itemSize = itemSize
//
//        flowLayout.sectionInset.top = 8
//        flowLayout.sectionInset.bottom = 8
//        flowLayout.sectionInset.left = 8
//        flowLayout.sectionInset.right = 8
//
//        flowLayout.minimumInteritemSpacing = minimumInterItemSpacing
//        flowLayout.minimumLineSpacing = minimumLineSpacing
    }
    
    func configureCollectionViewLayout(for searchScope: SearchScope) {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 5, bottom: 8, trailing: 5)
        let groupSize = NSCollectionLayoutSize(widthDimension: searchScope.groupWidthDimension, heightDimension: .absolute(166))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: searchScope.groupItemCount)
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = searchScope.orthogonalScrollBehavior
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(28))
        let headerItem = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: "Header", alignment: .topLeading)
        section.boundarySupplementaryItems = [headerItem]
        let layout =  UICollectionViewCompositionalLayout(section: section)
        collectionView.collectionViewLayout = layout
        
    }
    
    
    
    
}
