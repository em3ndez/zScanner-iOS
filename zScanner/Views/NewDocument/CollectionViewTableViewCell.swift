//
//  CollectionViewTableViewCell.swift
//  zScanner
//
//  Created by Jan Provazník on 28/05/2020.
//  Copyright © 2020 Institut klinické a experimentální medicíny. All rights reserved.
//

import UIKit
import RxSwift
import SnapKit

protocol CollectionViewCellDelegate {
    func reeditMedia(media: Media)
    func deleteDocument()
    func createNewMedia()
    func reload()
}

class CollectionViewTableViewCell: UITableViewCell {
    
    // MARK: Instance part
    private(set) var viewModel: MediaListViewModel?
    private var delegate: CollectionViewCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Lifecycle
    override func prepareForReuse() {
        super.prepareForReuse()
        
        viewModel = nil
        
        disposeBag = DisposeBag()
    }
    
    // MARK: Interface
    func setup(with field: CollectionViewField, viewModel: MediaListViewModel, delegate: CollectionViewCellDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        
        field.picturesCount.accept(viewModel.mediaArray.value.count)
        
        resetHeight()
        collectionView.reloadData()
    }
    
    func reloadCells() {
        collectionView.reloadData()
    }
    
    // MARK: Helpers
    private var disposeBag = DisposeBag()
    var heightConstraint: Constraint?
    
    private func setupView() {
        selectionStyle = .none
           
        preservesSuperviewLayoutMargins = true
        contentView.preservesSuperviewLayoutMargins = true
    
        contentView.addSubview(deleteButton)
        deleteButton.snp.makeConstraints { make in
            make.leading.trailing.centerX.bottom.equalToSuperview()
            make.height.equalTo(30)
        }
        
        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(deleteButton.snp.top).inset(-10)
        }
    }
    
    private func resetHeight() {
        let count = viewModel!.mediaArray.value.count + 1
        let elementsPair = (count+1)/2
        let newHeight = CGFloat(elementsPair) * (itemWidth + margin) + margin + deleteButton.frame.height
        
        heightConstraint?.deactivate()
        collectionView.snp.makeConstraints { make in
            heightConstraint = make.height.equalTo(newHeight).priority(999).constraint
        }
    }
    
    @objc private func deleteDocument() {
        delegate?.deleteDocument()
    }

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .white
        collectionView.isScrollEnabled = false
        
        collectionView.register(PhotoSelectorCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoSelectorCollectionViewCell")
        collectionView.register(AddNewMediaCollectionViewCell.self, forCellWithReuseIdentifier: "AddNewMediaCollectionViewCell")
        collectionView.dataSource = self
        return collectionView
    }()

    private lazy var flowLayout: UICollectionViewLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = margin
        layout.minimumLineSpacing = margin
        layout.sectionInset = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        return layout
    }()

    private let margin: CGFloat = 10
    private let numberofColumns: CGFloat = 2

    private var itemWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return (screenWidth - (numberofColumns + 1) * margin) / numberofColumns
    }
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton()
        let attributedString = NSAttributedString(string: "newDocumentPhotos.deleteDocument.title".localized,
                                                  attributes: [
                                                       .underlineStyle: NSUnderlineStyle.single.rawValue,
                                                       .foregroundColor: UIColor.red,
                                                       .font: UIFont.footnote
                                                  ])
        button.setAttributedTitle(attributedString, for: .normal)
        button.addTarget(self, action: #selector(deleteDocument), for: .touchUpInside)
        return button
    }()
}

// MARK: - UICollectionViewDataSource implementation
extension CollectionViewTableViewCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (viewModel?.mediaArray.value.count ?? 0) + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == viewModel?.mediaArray.value.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddNewMediaCollectionViewCell", for: indexPath) as! AddNewMediaCollectionViewCell
            cell.setup(delegate: self)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoSelectorCollectionViewCell", for: indexPath) as! PhotoSelectorCollectionViewCell
            let media = viewModel!.mediaArray.value[indexPath.row]
            cell.setup(with: media, delegate: self)
            return cell
        }
    }
}

// MARK: - PhotoSelectorCellDelegate implementation
extension CollectionViewTableViewCell: PhotoSelectorCellDelegate {
    func edit(media: Media) {
        delegate?.reeditMedia(media: media)
    }
    
    func delete(media: Media) {
        viewModel?.removeMedia(media)
        collectionView.reloadData()
        resetHeight()
        delegate?.reload()
    }
}

// MARK: - AddNewMediaCellDelegate implementation
extension CollectionViewTableViewCell: AddNewMediaCellDelegate {
    func createNewMedia() {
        delegate?.createNewMedia()
    }
}
