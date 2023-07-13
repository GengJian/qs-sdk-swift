//
//  VSWaterFlowLayout.swift
//  QuasiDemo
//
//  Created by Soul on 2023/3/7.
//  Copyright © 2023 Quasi Inc. All rights reserved.
//

import UIKit

@objc protocol WaterfallMutiSectionDelegate: NSObjectProtocol {
  // 必选delegate实现
  /// collectionItem高度
  func heightForRowAtIndexPath(collectionView collection: UICollectionView, layout: VSWaterfallFlowLayout, indexPath: IndexPath, itemWidth: CGFloat) -> CGFloat

  // 可选delegate实现
  /// 每个section 列数（默认2列）
  @objc optional func columnNumber(collectionView collection: UICollectionView, layout: VSWaterfallFlowLayout, section: Int) -> Int

  /// header高度（默认为0）
  @objc optional func referenceSizeForHeader(collectionView collection: UICollectionView, layout: VSWaterfallFlowLayout, section: Int) -> CGSize

  /// footer高度（默认为0）
  @objc optional func referenceSizeForFooter(collectionView collection: UICollectionView, layout: VSWaterfallFlowLayout, section: Int) -> CGSize

  /// 每个section 边距（默认为0）
  @objc optional func insetForSection(collectionView collection: UICollectionView, layout: VSWaterfallFlowLayout, section: Int) -> UIEdgeInsets

  /// 每个section item上下间距（默认为0）
  @objc optional func lineSpacing(collectionView collection: UICollectionView, layout: VSWaterfallFlowLayout, section: Int) -> CGFloat

  /// 每个section item左右间距（默认为0）
  @objc optional func interitemSpacing(collectionView collection: UICollectionView, layout: VSWaterfallFlowLayout, section: Int) -> CGFloat

  /// section头部header与上个section尾部footer间距（默认为0）
  @objc optional func spacingWithLastSection(collectionView collection: UICollectionView, layout: VSWaterfallFlowLayout, section: Int) -> CGFloat
}

/// 瀑布流布局
class VSWaterfallFlowLayout: UICollectionViewFlowLayout {
    weak var delegate: WaterfallMutiSectionDelegate?

  private var sectionInsets: UIEdgeInsets = .zero
  private var columnCount: Int = 2
  private var lineSpacing: CGFloat = 0
  private var interitemSpacing: CGFloat = 0
  private var headerSize: CGSize = .zero
  private var footerSize: CGSize = .zero

  // 存放attribute的数组
  private var attrsArray: [UICollectionViewLayoutAttributes] = []
  // 存放每个section中各个列的最后一个高度
  private var columnHeights: [CGFloat] = []
  // collectionView的Content的高度
  private var contentHeight: CGFloat = 0
  // 记录上个section高度最高一列的高度
  private var lastContentHeight: CGFloat = 0
  // 每个section的header与上个section的footer距离
  private var spacingWithLastSection: CGFloat = 0

    override func prepare() {
    super.prepare()
    self.contentHeight = 0
    self.lastContentHeight = 0
    self.spacingWithLastSection = 0
    self.lineSpacing = 0
    self.sectionInsets = .zero
    self.headerSize = .zero
    self.footerSize = .zero
    self.columnHeights.removeAll()
    self.attrsArray.removeAll()

        let sectionCount = self.collectionView?.numberOfSections ?? 0
        guard let cv = self.collectionView else {
            return
        }

    // 遍历section
    for idx in 0..<sectionCount {
      let indexPath = IndexPath(item: 0, section: idx)
      if let columnCount = self.delegate?.columnNumber?(collectionView: cv, layout: self, section: indexPath.section) {
        self.columnCount = columnCount
      }
      if let inset = self.delegate?.insetForSection?(collectionView: cv, layout: self, section: indexPath.section) {
        self.sectionInsets = inset
      }
      if let spacingLastSection = self.delegate?.spacingWithLastSection?(collectionView: cv, layout: self, section: indexPath.section) {
        self.spacingWithLastSection = spacingLastSection
      }
      // 生成header
      let itemCount = cv.numberOfItems(inSection: idx)
      let headerAttri = self.layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: indexPath)
      if let header = headerAttri {
        self.attrsArray.append(header)
        self.columnHeights.removeAll()
      }
      self.lastContentHeight = self.contentHeight
      // 初始化区 y值
      for _ in 0..<self.columnCount {
        self.columnHeights.append(self.contentHeight)
      }
      // 多少个item
      for item in 0..<itemCount {
        let indexPat = IndexPath(item: item, section: idx)
        let attri = self.layoutAttributesForItem(at: indexPat)
        if let attri = attri {
          self.attrsArray.append(attri)
        }
      }

      // 初始化footer
        let footerAttri = self.layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionFooter, at: indexPath)
      if let footer = footerAttri {
        self.attrsArray.append(footer)
      }
    }
  }

  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    return self.attrsArray
  }

  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
      guard let cv = self.collectionView else {
          return nil
      }

    if let column = self.delegate?.columnNumber?(collectionView: cv, layout: self, section: indexPath.section) {
      self.columnCount = column
    }
    if let lineSpacing = self.delegate?.lineSpacing?(collectionView: cv, layout: self, section: indexPath.section) {
      self.lineSpacing = lineSpacing
    }
    if let interitem = self.delegate?.interitemSpacing?(collectionView: cv, layout: self, section: indexPath.section) {
      self.interitemSpacing = interitem
    }

    let attri = UICollectionViewLayoutAttributes(forCellWith: indexPath)
    let weight = cv.frame.size.width
    let itemSpacing = CGFloat(self.columnCount - 1) * self.interitemSpacing
    let allWeight = weight - self.sectionInsets.left - self.sectionInsets.right - itemSpacing
    let cellWeight = allWeight / CGFloat(self.columnCount)
    let cellHeight: CGFloat = (
        self.delegate?.heightForRowAtIndexPath(
            collectionView: cv,
            layout: self,
            indexPath: indexPath,
            itemWidth: cellWeight
        )
    ) ?? 50

    var tmpMinColumn = 0
    var minColumnHeight = self.columnHeights[0]
    for i in 0..<self.columnCount {
      let columnH = self.columnHeights[i]
      if minColumnHeight > columnH {
        minColumnHeight = columnH
        tmpMinColumn = i
      }
    }
    let cellX = self.sectionInsets.left + CGFloat(tmpMinColumn) * (cellWeight + self.interitemSpacing)
    var cellY: CGFloat = 0
    cellY = minColumnHeight
    if cellY != self.lastContentHeight {
      cellY += self.lineSpacing
    }

    if self.contentHeight < minColumnHeight {
      self.contentHeight = minColumnHeight
    }

    attri.frame = CGRect(x: cellX, y: cellY, width: cellWeight, height: cellHeight)
    self.columnHeights[tmpMinColumn] = attri.frame.maxY
      // 取最大的
      for i in 0..<self.columnHeights.count where self.contentHeight < self.columnHeights[i] {
          self.contentHeight = self.columnHeights[i]
      }

    return attri
  }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attri = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind, with: indexPath)
        guard let cv = self.collectionView else {
            return attri
        }

        if elementKind == UICollectionElementKindSectionHeader {
            if let headerSize = self.delegate?.referenceSizeForHeader?(collectionView: cv, layout: self, section: indexPath.section) {
                self.headerSize = headerSize
            }
            self.contentHeight += self.spacingWithLastSection
            attri.frame = CGRect(x: 0, y: self.contentHeight, width: self.headerSize.width, height: self.headerSize.height)
            self.contentHeight += self.headerSize.height
            self.contentHeight += self.sectionInsets.top
        } else if elementKind == UICollectionElementKindSectionFooter {
            if let footerSize = self.delegate?.referenceSizeForFooter?(collectionView: cv, layout: self, section: indexPath.section) {
                self.footerSize = footerSize
            }
            self.contentHeight += self.sectionInsets.bottom
            attri.frame = CGRect(x: 0, y: self.contentHeight, width: self.footerSize.width, height: self.footerSize.height)
            self.contentHeight += self.footerSize.height
        }
        return attri
    }

    override var collectionViewContentSize: CGSize {
        guard let cv = self.collectionView else {
            return .zero
        }

        return CGSize(width: cv.frame.size.width, height: self.contentHeight)
    }
}
