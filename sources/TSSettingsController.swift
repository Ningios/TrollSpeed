//
//  TSSettingsController.swift
//  TrollSpeed
//
//  Created by Lessica on 2024/1/24.
//

import UIKit

@objc public protocol TSSettingsControllerDelegate {
    func settingHighlighted(key: String) -> Bool
    func settingDidSelect(key: String) -> Void

    // 大卡片（字体大小 / 偏移位置）
    func settingBoolValue(key: String) -> Bool
    func settingNumberValue(key: String) -> Double
    func setSettingBoolValue(_ value: Bool, forKey key: String)
    func setSettingNumberValue(_ value: Double, forKey key: String)
    func resetCustomFontAndOffset()
}

@objc open class TSSettingsController : SPLarkSettingsController
{
    @objc open weak var delegate: TSSettingsControllerDelegate?
    @objc open var alreadyLaunched: Bool = false
    internal var restartRequired = false

    open override func settingsCount() -> Int {
        return TSSettingsIndex.allCases.count
    }

    // MARK: - 大卡片

    private func isBigCard(index: Int) -> Bool {
        return TSSettingsIndex.allCases[index] == .customFontOffset
    }

    open override func settingReuseIdentifier(index: Int) -> String {
        guard isBigCard(index: index) else {
            return super.settingReuseIdentifier(index: index)
        }
        return TSSettingsBigCardCell.reuseIdentifier
    }

    open override func settingItemSize(index: Int) -> CGSize {
        guard isBigCard(index: index) else {
            return super.settingItemSize(index: index)
        }
        // 2 张卡片宽 ≈ 1.5 张（240），2 张卡片高（129.5）
        return CGSize(width: 240, height: 129.5)
    }

    open override func settingWillDisplay(cell: UICollectionViewCell, index: Int) {
        guard let bigCell = cell as? TSSettingsBigCardCell else { return }
        bigCell.configure(with: self)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(TSSettingsBigCardCell.self,
                                forCellWithReuseIdentifier: TSSettingsBigCardCell.reuseIdentifier)
    }

    open override func settingTitle(index: Int, highlighted: Bool) -> String {
        return TSSettingsIndex.allCases[index].title
    }

    open override func settingSubtitle(index: Int, highlighted: Bool) -> String? {
        if isBigCard(index: index) {
            let usesFontSize = delegate?.settingBoolValue(key: HUDUserDefaultsKeyUsesCustomFontSize) ?? false
            let usesOffset = delegate?.settingBoolValue(key: HUDUserDefaultsKeyUsesCustomOffset) ?? false
            return (usesFontSize || usesOffset)
                ? NSLocalizedString("Custom", comment: "TSSettingsIndex")
                : NSLocalizedString("Default", comment: "TSSettingsIndex")
        }
        return TSSettingsIndex.allCases[index].subtitle(highlighted: highlighted, restartRequired: restartRequired)
    }

    private func settingKey(index: Int) -> String {
        return TSSettingsIndex.allCases[index].key
    }

    open override func settingHighlighted(index: Int) -> Bool {
        return delegate?.settingHighlighted(key: settingKey(index: index)) ?? false
    }

    private var isFPSMode: Bool {
        return delegate?.settingHighlighted(key: HUDUserDefaultsKeyDisplayMode) ?? false
    }

    open override func settingEnabled(index: Int) -> Bool {
        guard isFPSMode else { return true }
        let setting = TSSettingsIndex.allCases[index]
        switch setting {
        case .singleLineMode, .usesArrowPrefixes, .usesBitrate:
            return false
        default:
            return true
        }
    }

    open override func settingColorHighlighted(index: Int) -> UIColor {
        return UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 28/255.0, green: 74/255.0, blue: 82/255.0, alpha: 1.0)
            } else {
                return UIColor(red: 22/255.0, green: 160/255.0, blue: 133/255.0, alpha: 1.0)
            }
        }
    }

    open override func settingDidSelect(index: Int, completion: @escaping () -> ()) {
        // 大卡片自己处理开关/滑杆，不参与「点一下切换」的行选中逻辑
        if isBigCard(index: index) {
            completion()
            return
        }
        if index == TSSettingsIndex.passthroughMode.rawValue && alreadyLaunched {
            restartRequired = true
        }
        delegate?.settingDidSelect(key: settingKey(index: index))
        completion()

        // When display mode is toggled, update enabled/disabled state of affected cells in-place
        if index == TSSettingsIndex.displayMode.rawValue {
            for cell in collectionView.visibleCells {
                if let settingCell = cell as? SPLarkSettingsCollectionViewCell,
                   let indexPath = collectionView.indexPath(for: settingCell) {
                    settingCell.setEnabled(settingEnabled(index: indexPath.row))
                }
            }
        }
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        guard let currentOrientation = view.window?.windowScene?.interfaceOrientation else {
            return [.portrait]
        }
        switch currentOrientation {
        case .unknown: fallthrough
        case .portrait:
            return [.portrait]
        case .portraitUpsideDown:
            return [.portraitUpsideDown]
        case .landscapeLeft:
            return [.landscapeLeft]
        case .landscapeRight:
            return [.landscapeRight]
        @unknown default:
            return [.portrait]
        }
    }

    open override var shouldAutorotate: Bool { false }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != self.traitCollection.userInterfaceStyle {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
