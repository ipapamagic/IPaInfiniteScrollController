//
//  IPaInfiniteScrollController.swift
//  IPaInfiniteScrollController
//
//  Created by IPa Chen on 2018/11/24.
//

import UIKit
@objc public protocol IPaInfiniteScrollControllerDelegate {
    @objc func infiniteScrollController(_ controller:IPaInfiniteScrollController,didScrollTo page:Int)
}
@objc open class IPaInfiniteScrollController: NSObject {
    var collectionView:UICollectionView!
    public var controllerDelegate:IPaInfiniteScrollControllerDelegate?
    public var delegate:UICollectionViewDelegateFlowLayout?
    public var dataSource:UICollectionViewDataSource?
    fileprivate var itemScale = 3
    fileprivate var originalContentSize:CGFloat = 0
    fileprivate var finalItemCount = 0
    public var isPaging = false
    fileprivate var _currentPage = 0
    public var currentPage:Int {
        get {
            return _currentPage
        }
        set {
            self.set(newValue, animated: false)
        }
    }
    public init(collectionView:UICollectionView) {
        super.init()
        self.collectionView = collectionView
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        self.delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout
        self.dataSource = collectionView.dataSource
        collectionView.delegate = self
        collectionView.dataSource = self
        self.reloadData()
    }
    fileprivate func moveToCenter() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            
            let currentOffset = (layout.scrollDirection == .horizontal) ? self.collectionView.contentOffset.x : self.collectionView.contentOffset.y
            var value = currentOffset
            while value >= self.originalContentSize {
                value -= self.originalContentSize
            }
            let halfItemScale = self.itemScale / 2
            value += CGFloat(halfItemScale) * self.originalContentSize
            
            if layout.scrollDirection == .horizontal {
                self.collectionView.setContentOffset(CGPoint(x: value, y: 0), animated: false)
            }
            else {
                self.collectionView.setContentOffset(CGPoint(x: 0, y: value), animated: false)
            }
        })
        
        

        
    }
    public func set(_ page:Int,animated:Bool) {
        if page == _currentPage {
            return
        }
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let itemSize = layout.itemSize
        let singleValue = (layout.scrollDirection == .horizontal) ? itemSize.width : itemSize.height
        
        var value:CGFloat
        var offset = CGPoint.zero
        if !animated {
            value = singleValue * CGFloat(page)
            
        }
        else {
            var lowerPage:Int
            var upperPage:Int
            let itemValue = ((layout.scrollDirection == .horizontal) ?  itemSize.width : itemSize.height)
            let totalPage = Int(originalContentSize / itemValue)
            if page > _currentPage {
                lowerPage = page - totalPage
                upperPage = page
            }
            else {
                lowerPage = page
                upperPage = page + totalPage
            }
            let lowerDis = _currentPage - lowerPage
            let upperDis = upperPage - _currentPage
            let currentOffsetValue = (layout.scrollDirection == .horizontal) ? collectionView.contentOffset.x : collectionView.contentOffset.y
            
            if lowerDis > upperDis {
                //goto upperPage
                value = itemValue * CGFloat(upperDis) + currentOffsetValue
            }
            else {
                //goto lowerPage
                value = currentOffsetValue - (itemValue * CGFloat(lowerDis))
            }
        }
        offset = (layout.scrollDirection == .horizontal) ? CGPoint(x: value, y: 0) : CGPoint(x: 0, y: value)
        _currentPage = page
        collectionView.setContentOffset(offset, animated: animated)
        if !animated {
            self.moveToCenter()
        }
    }
    fileprivate func moveToClosetItem() {
        guard let numberOfItems = self.dataSource?.collectionView(collectionView,numberOfItemsInSection:1) ,numberOfItems > 0 else {
            return
        }
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let itemSize = layout.itemSize
        var newOffset = CGPoint.zero
        if layout.scrollDirection == .horizontal {

            let item = itemSize.width
            let textValue = self.collectionView.contentOffset.x
            let index = Int(textValue / item + 0.5)
            newOffset.x = item * CGFloat(index)

        }
        else {
            let item = itemSize.height
            let textValue = self.collectionView.contentOffset.y
            let index = Int(textValue / item + 0.5)
            newOffset.y = item * CGFloat(index)
        }
        if newOffset.equalTo(collectionView.contentOffset) {
            self.moveToCenter()
        }
        else {
            collectionView.setContentOffset(newOffset, animated: true)
        }
        print("didMove to nearest:\(newOffset.x)")
    }
    fileprivate func recaculatorData() {
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        
        guard let numberOfItems = self.dataSource?.collectionView(collectionView,numberOfItemsInSection:0) ,numberOfItems > 0 else {
            return
        }
        let itemSize = layout.itemSize
        
        let value = ((layout.scrollDirection == .horizontal) ? itemSize.width : itemSize.height)
        let containerValue = (layout.scrollDirection == .horizontal) ? collectionView.bounds.width : collectionView.bounds.height
        
        let numberInPage:Int = Int(ceil(containerValue / value)) + 2
        self.originalContentSize = CGFloat(numberOfItems) * value
        var finalNumberOfItems = numberOfItems * 3
        itemScale = 3
        while(numberInPage > finalNumberOfItems) {
            finalNumberOfItems += (numberOfItems * 2)
            itemScale += 2
            
        }
        itemScale += 10
        finalNumberOfItems += (numberOfItems * 10)
        finalItemCount = finalNumberOfItems
    }
    public func reloadData() {
        recaculatorData()
        self.collectionView.reloadData()
        moveToCenter()
    }
}
extension IPaInfiniteScrollController:UICollectionViewDelegateFlowLayout,UICollectionViewDataSource
{
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return finalItemCount
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let numberOfItems = self.dataSource!.collectionView(collectionView,numberOfItemsInSection:indexPath.section)
        let item = indexPath.item % numberOfItems
        
        return self.dataSource!.collectionView(collectionView,cellForItemAt:IndexPath(item: item, section: indexPath.section))
    }
    
    
    
}
extension IPaInfiniteScrollController:UIScrollViewDelegate
{
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if self.isPaging {
//            self.moveToClosetItem()
        }
        else {
            self.moveToCenter()
        }
    }
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            if self.isPaging {
//                self.moveToClosetItem()
            }
            else {
                self.moveToCenter()
            }
        }
    }
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.moveToCenter()
        if self.isPaging {
            self.moveToClosetItem()
        }
    }
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let itemSize = layout.itemSize
        let currentOffset = (layout.scrollDirection == .horizontal) ? collectionView.contentOffset.x : collectionView.contentOffset.y
        let value = CGFloat(Int(currentOffset) % Int(originalContentSize))

        let singleValue = (layout.scrollDirection == .horizontal) ? itemSize.width : itemSize.height

        let newPage = Int(value / singleValue)
        if newPage != _currentPage {
            _currentPage = newPage
            if let controllerDelegate = controllerDelegate {
                
                controllerDelegate.infiniteScrollController(self, didScrollTo: self._currentPage)
                
                
                
                
            }
        }
        
    }
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let itemSize = layout.itemSize
        let pageSize = (layout.scrollDirection == .horizontal) ? itemSize.width : itemSize.height
        let targetX: CGFloat = scrollView.contentOffset.x + velocity.x * 60.0
        var targetIndex: CGFloat = round(targetX / pageSize)
        if targetIndex < 0 {
            targetIndex = 0
        }
        
        if velocity.x > 0 {
            targetIndex = ceil(targetX / pageSize)
        } else {
            targetIndex = floor(targetX / pageSize)
        }
        
        var offsetX = targetIndex * pageSize - scrollView.contentInset.left
        offsetX = min(offsetX, scrollView.contentSize.width - scrollView.bounds.width + scrollView.contentInset.right)
        targetContentOffset.pointee.x = offsetX
        
    }
}
