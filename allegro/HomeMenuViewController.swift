//
//  HomeMenuViewController.swift
//  allegro
//
//  Created by Brian Tiger Chow on 1/12/17.
//  Copyright © 2017 gigaunicorn. All rights reserved.
//

import UIKit

class HomeMenuViewController: UIViewController {
    
    private let logo: UIImageView = {
        let v = UIImageView()
        v.backgroundColor = UIColor.purple
        return v
    }()
    
    private let newCompositionButton: UIButton = {
        let v = UIButton()
        v.backgroundColor = UIColor.gray
        v.setTitle("New", for: .normal)
        return v
    }()

    private let instructionsButton: UIButton = {
        let v = UIButton()
        v.backgroundColor = UIColor.gray
        v.setTitle("Instructions", for: .normal)
        return v
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.green
        
        view.addSubview(logo)
        view.addSubview(newCompositionButton)
        view.addSubview(instructionsButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews() // NB: does nothing

        let DEFAULT_MARGIN_PTS: CGFloat = 22 // an aesthetic choice
        let parent = view.bounds
        let centerX = parent.width / 2

        let logoH = parent.height / 2 - 2 * DEFAULT_MARGIN_PTS
        let logoW = logoH * THE_GOLDEN_RATIO

        logo.frame = CGRect(x: centerX - logoW / 2,
                            y: DEFAULT_MARGIN_PTS,
                            width: logoW,
                            height: logoH)

        let numButtons = [newCompositionButton, instructionsButton].count
        
        // FYI: this buttonH value ends up being 60.5 on iPhone 6
        let buttonH: CGFloat = (parent.height / 2 - 3 * DEFAULT_MARGIN_PTS) / CGFloat(numButtons)
        let buttonW = buttonH * 5 // is an educated guess

        newCompositionButton.frame = CGRect(x: centerX - buttonW / 2,
                                            y: parent.height / 2 + DEFAULT_MARGIN_PTS,
                                            width: buttonW,
                                            height: buttonH)

        instructionsButton.frame = CGRect(x: centerX - buttonW / 2,
                                          y: newCompositionButton.frame.maxY + DEFAULT_MARGIN_PTS,
                                          width: buttonW,
                                          height: buttonH)
    }
}
