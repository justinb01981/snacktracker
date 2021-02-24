//
//  FoodDetailsView.swift
//  snacktracker
//
//  Created by Justin Brady on 2/19/21.
//  Copyright © 2021 Justin Brady. All rights reserved.
//

import Foundation
import UIKit

enum MealTypeEnum: String {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
}

struct FoodDetailsModel {
    var name: String!
    var servingSize: String!
    var time: Date!
    var type: MealTypeEnum!
    var tag: String!
}

protocol FoodDetailsViewDelegate {
    func onSave(_ foodDetails: FoodDetailsModel)
    func onCancel()
    
    var lastImage: UIImage! { get }
}

class FoodDetailsView: UIView {
    
    static let allMealTypes = [MealTypeEnum.breakfast, MealTypeEnum.lunch, MealTypeEnum.dinner, MealTypeEnum.snack]
    
    var nameField: UITextField!
    var servingSizeField: UITextField!
    var timeField: UITextField!
    var mealTypeField: UISegmentedControl!
    var serverTagField: UITextField!
    var saveButton: UIButton!
    var cancelButton: UIButton!
    var waitSpinner: UIActivityIndicatorView!
    
    var delegate: FoodDetailsViewDelegate?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    init() {
        super.init(frame: CGRect.zero)
        setup()
    }
    
    private func setup() {
        let stackView = UIStackView()
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        
        layer.cornerRadius = 8.0
        
        nameField = UITextField()
        servingSizeField = UITextField()
        timeField = UITextField()
        mealTypeField = UISegmentedControl()
        serverTagField = UITextField()
        saveButton = UIButton()
        cancelButton = UIButton()
        waitSpinner = UIActivityIndicatorView()
        
        // name entry field
        let nameLabel = UILabel()
        nameLabel.text = "Name"
        let nameStack = UIStackView()
        nameStack.axis = .horizontal
        nameStack.alignment = .center
        //nameStack.addArrangedSubview(nameLabel)
        nameStack.addArrangedSubview(nameField)
        stackView.addArrangedSubview(nameStack)
        
        // serving size
        let sizeLabel = UILabel()
        sizeLabel.text = "Serving Size"
        let sizeStack = UIStackView()
        sizeStack.axis = .horizontal
        sizeStack.addArrangedSubview(sizeLabel)
        sizeStack.addArrangedSubview(servingSizeField)
        stackView.addArrangedSubview(sizeStack)
        
        // time
        stackView.addArrangedSubview(timeField)
        
        // type of meal selector
        stackView.addArrangedSubview(mealTypeField)
        
        // AI classification
        let classLabel = UILabel()
        classLabel.text = "Classification"
        let classStack = UIStackView()
        classStack.axis = .horizontal
        classStack.addArrangedSubview(classLabel)
        classStack.addArrangedSubview(serverTagField)
        stackView.addArrangedSubview(classStack)
        
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.addArrangedSubview(saveButton)
        buttonStack.addArrangedSubview(cancelButton)
        stackView.addArrangedSubview(buttonStack)
        stackView.addArrangedSubview(waitSpinner)
        
        nameField.placeholder = "Name"
        servingSizeField.placeholder = "Serving size"
        timeField.text = FoodLog.shared.dateFormatter.string(from: Date())
        serverTagField.placeholder = "Classification"
        
        timeField.isUserInteractionEnabled = false
        
        for option in FoodDetailsView.allMealTypes {
            mealTypeField.insertSegment(withTitle: option.rawValue, at: mealTypeField.numberOfSegments, animated: false)
        }
        mealTypeField.selectedSegmentIndex = 0
        
        for field in [nameField, servingSizeField, timeField, serverTagField] {
            field?.textColor = UIColor.white
            field?.textAlignment = .center
        }
        saveButton.setTitle("✅ Save", for: .normal)
        cancelButton.setTitle("❌ Cancel", for: .normal)
        
        saveButton.addTarget(self, action: #selector(onSave), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(onCancel), for: .touchUpInside)
        
        addSubview(stackView)
        
        nameField.textAlignment = .center
        
        addConstraints([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        backgroundColor = UIColor.gray.withAlphaComponent(0.9)
    }
    
    @objc func onSave(_ sender: Any) {
        
        guard let mealType = MealTypeEnum(rawValue: mealTypeField.titleForSegment(at: mealTypeField.selectedSegmentIndex) ?? ""),
            let delegate = self.delegate else {
            // TODO: raise error to user
            return
        }
        
        if nameField.text?.count == 0, servingSizeField.text?.count == 0 {
            return
        }
        
        nameField.resignFirstResponder()
        servingSizeField.resignFirstResponder()
        
        waitSpinner.startAnimating()
        
        //DispatchQueue(label: "IdentifierQueue").async {
            IdentifyMealManager.shared.identify(delegate.lastImage) {
                [unowned self] (request) in
                
                var model = FoodDetailsModel(name: self.nameField.text, servingSize: self.servingSizeField.text, time: Date(), type: mealType, tag: "Unknown")
                if let result = request.result,
                    let p = result.predictions.first {
                    model.tag = p.tagName
                    self.serverTagField.text = model.tag
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                    [weak self] in
                    self?.waitSpinner.stopAnimating()
                    self?.delegate?.onSave(model)
                })
            }
        //}
    }
    
    @objc func onCancel(_ sender: Any) {
        delegate?.onCancel()
    }
}
