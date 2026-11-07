//
//  TSSettingsBigCardCell.swift
//  TrollSpeed
//
//  大卡片：把原「系统设置 → TrollSpeed」那页的字体大小 / 偏移位置搬进 App 内。
//  尺寸 = 2 张卡片宽 × 2 张卡片高（见 TSSettingsController.settingItemSize）。
//

import UIKit

final class TSSettingsBigCardCell: SPLarkSettingsCollectionViewCell {

    static let reuseIdentifier = "TSSettingsBigCardCell"

    // 与 prefs 子工程 Root.plist 保持一致
    private let fontSizeMin: Float = 8
    private let fontSizeMax: Float = 12
    private let fontSizeDefault: Float = 9
    private let offsetXMin: Float = -600
    private let offsetXMax: Float = 600
    private let offsetYMin: Float = -100
    private let offsetYMax: Float = 100

    private let hInset: CGFloat = 13
    private let cardCornerRadius: CGFloat = 16
    private let controlScale: CGFloat = 0.78   // 1x 控件缩到卡片里的大小

    weak var settingsController: TSSettingsController?

    private let cardTitleLabel = UILabel()
    private let resetButton = UIButton(type: .system)
    private let fontSizeLabel = UILabel()
    private let fontSizeSwitch = UISwitch()
    private let fontSizeSlider = UISlider()
    private let fontSizeValueLabel = UILabel()
    private let offsetLabel = UILabel()
    private let offsetSwitch = UISwitch()
    private let offsetXSlider = UISlider()
    private let offsetXValueLabel = UILabel()
    private let offsetYSlider = UISlider()
    private let offsetYValueLabel = UILabel()

    // MARK: - Init

    override func commonInit() {
        super.commonInit()

        // 基类的标题/副标题不参与大卡片的排版
        titleLabel.isHidden = true
        subtitleLabel.isHidden = true

        // 自定义 cell 不会走基类的「刷底色」流程，这里补上（与其它卡片同一套：white 0.1）
        setHighlighted(false, color: UIColor.white.withAlphaComponent(0.10))

        cardTitleLabel.text = NSLocalizedString("Font & Offset", comment: "TSSettingsBigCardCell")
        cardTitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        cardTitleLabel.textColor = .white
        contentView.addSubview(cardTitleLabel)

        resetButton.setTitle(NSLocalizedString("Reset", comment: "TSSettingsBigCardCell"), for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 11, weight: .regular)
        resetButton.setTitleColor(UIColor(white: 1.0, alpha: 0.46), for: .normal)
        resetButton.addTarget(self, action: #selector(tapResetButton(_:)), for: .touchUpInside)
        contentView.addSubview(resetButton)

        fontSizeLabel.text = NSLocalizedString("Custom Font Size", comment: "TSSettingsBigCardCell")
        fontSizeLabel.font = .systemFont(ofSize: 12, weight: .regular)
        fontSizeLabel.textColor = UIColor(white: 1.0, alpha: 0.88)
        contentView.addSubview(fontSizeLabel)

        configureSwitch(fontSizeSwitch, action: #selector(fontSizeSwitchChanged(_:)))

        offsetLabel.text = NSLocalizedString("Custom Offset", comment: "TSSettingsBigCardCell")
        offsetLabel.font = .systemFont(ofSize: 12, weight: .regular)
        offsetLabel.textColor = UIColor(white: 1.0, alpha: 0.88)
        contentView.addSubview(offsetLabel)

        configureSwitch(offsetSwitch, action: #selector(offsetSwitchChanged(_:)))

        configureSlider(fontSizeSlider, min: fontSizeMin, max: fontSizeMax, action: #selector(fontSizeSliderChanged(_:)))
        configureSlider(offsetXSlider, min: offsetXMin, max: offsetXMax, action: #selector(offsetXSliderChanged(_:)))
        configureSlider(offsetYSlider, min: offsetYMin, max: offsetYMax, action: #selector(offsetYSliderChanged(_:)))

        for valueLabel in [fontSizeValueLabel, offsetXValueLabel, offsetYValueLabel] {
            valueLabel.font = .systemFont(ofSize: 10.5, weight: .regular)
            valueLabel.textColor = UIColor(white: 1.0, alpha: 0.48)
            valueLabel.textAlignment = .right
            contentView.addSubview(valueLabel)
        }
    }

    private func configureSwitch(_ toggle: UISwitch, action: Selector) {
        toggle.addTarget(self, action: action, for: .valueChanged)
        toggle.transform = CGAffineTransform(scaleX: controlScale, y: controlScale)
        contentView.addSubview(toggle)
    }

    private func configureSlider(_ slider: UISlider, min: Float, max: Float, action: Selector) {
        slider.minimumValue = min
        slider.maximumValue = max
        slider.isContinuous = false   // 松手才写盘 + 通知 HUD
        slider.addTarget(self, action: action, for: .valueChanged)
        slider.transform = CGAffineTransform(scaleX: controlScale, y: controlScale)
        contentView.addSubview(slider)
    }

    // MARK: - 排版

    /// 用「目标可视矩形 + 缩放」摆放控件，避免 transform 影响位置计算
    private func place(_ view: UIView, visualRect: CGRect, scale: CGFloat) {
        view.bounds = CGRect(x: 0, y: 0, width: visualRect.width / scale, height: visualRect.height / scale)
        view.center = CGPoint(x: visualRect.midX, y: visualRect.midY)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        backgroundColorView.layer.cornerRadius = cardCornerRadius
        backgroundColorView.layer.cornerCurve = .continuous

        let width = contentView.bounds.width
        let rightX = width - hInset
        let switchVisualWidth: CGFloat = 40
        let switchVisualHeight: CGFloat = 22
        let valueWidth: CGFloat = 24
        let valueGap: CGFloat = 7
        let switchX = rightX - switchVisualWidth

        // 标题行
        cardTitleLabel.frame = CGRect(x: hInset, y: 9, width: switchX - hInset, height: 16)
        resetButton.frame = CGRect(x: rightX - 66, y: 4, width: 66, height: 26)
        resetButton.contentHorizontalAlignment = .right

        // 自定义字体大小（开关）
        let fontSwitchCenterY: CGFloat = 39
        fontSizeLabel.frame = CGRect(x: hInset, y: fontSwitchCenterY - 10, width: switchX - hInset - 8, height: 20)
        place(fontSizeSwitch,
              visualRect: CGRect(x: switchX, y: fontSwitchCenterY - switchVisualHeight / 2,
                                 width: switchVisualWidth, height: switchVisualHeight),
              scale: controlScale)

        // 字号滑杆
        let fontValueX = rightX - valueWidth
        place(fontSizeSlider,
              visualRect: CGRect(x: hInset, y: 52, width: fontValueX - valueGap - hInset, height: 20),
              scale: controlScale)
        fontSizeValueLabel.frame = CGRect(x: fontValueX, y: 54, width: valueWidth, height: 16)

        // 自定义偏移位置（开关）
        let offsetSwitchCenterY: CGFloat = 86
        offsetLabel.frame = CGRect(x: hInset, y: offsetSwitchCenterY - 10, width: switchX - hInset - 8, height: 20)
        place(offsetSwitch,
              visualRect: CGRect(x: switchX, y: offsetSwitchCenterY - switchVisualHeight / 2,
                                 width: switchVisualWidth, height: switchVisualHeight),
              scale: controlScale)

        // X / Y 并排
        let blockWidth = (rightX - hInset - 14) / 2
        let sliderWidth = blockWidth - valueGap - valueWidth
        let xSliderX = hInset
        let yBlockX = hInset + blockWidth + 14
        place(offsetXSlider,
              visualRect: CGRect(x: xSliderX, y: 99, width: sliderWidth, height: 20),
              scale: controlScale)
        offsetXValueLabel.frame = CGRect(x: xSliderX + sliderWidth + valueGap, y: 101,
                                         width: valueWidth, height: 16)
        place(offsetYSlider,
              visualRect: CGRect(x: yBlockX, y: 99, width: sliderWidth, height: 20),
              scale: controlScale)
        offsetYValueLabel.frame = CGRect(x: yBlockX + sliderWidth + valueGap, y: 101,
                                         width: valueWidth, height: 16)
    }

    // 大卡片不做按压缩放动画（否则拖滑杆时整张卡会抖）
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {}
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {}

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.isHidden = true
        subtitleLabel.isHidden = true
        setHighlighted(false, color: UIColor.white.withAlphaComponent(0.10))
        applyValues(animated: false)
    }

    // MARK: - 数据

    func configure(with controller: TSSettingsController) {
        settingsController = controller
        setHighlighted(false, color: UIColor.white.withAlphaComponent(0.10))
        applyValues(animated: false)
    }

    private func applyValues(animated: Bool) {
        guard let delegate = settingsController?.delegate else { return }

        let usesFontSize = delegate.settingBoolValue(key: HUDUserDefaultsKeyUsesCustomFontSize)
        let fontValue = delegate.settingNumberValue(key: HUDUserDefaultsKeyRealCustomFontSize)
        let usesOffset = delegate.settingBoolValue(key: HUDUserDefaultsKeyUsesCustomOffset)
        let offsetX = delegate.settingNumberValue(key: HUDUserDefaultsKeyRealCustomOffsetX)
        let offsetY = delegate.settingNumberValue(key: HUDUserDefaultsKeyRealCustomOffsetY)

        fontSizeSwitch.setOn(usesFontSize, animated: animated)
        fontSizeSlider.value = Float(fontValue)
        offsetSwitch.setOn(usesOffset, animated: animated)
        offsetXSlider.value = Float(offsetX)
        offsetYSlider.value = Float(offsetY)

        updateValueLabels()
        updateEnabledState()
    }

    private func updateValueLabels() {
        fontSizeValueLabel.text = String(format: "%.2f", fontSizeSlider.value)
        offsetXValueLabel.text = String(format: "%.1f", offsetXSlider.value)
        offsetYValueLabel.text = String(format: "%.1f", offsetYSlider.value)
    }

    private func updateEnabledState() {
        let fontEnabled = fontSizeSwitch.isOn
        fontSizeSlider.isEnabled = fontEnabled
        fontSizeSlider.alpha = fontEnabled ? 1.0 : 0.55
        fontSizeValueLabel.alpha = fontEnabled ? 1.0 : 0.62

        let offsetEnabled = offsetSwitch.isOn
        offsetXSlider.isEnabled = offsetEnabled
        offsetYSlider.isEnabled = offsetEnabled
        offsetXSlider.alpha = offsetEnabled ? 1.0 : 0.55
        offsetYSlider.alpha = offsetEnabled ? 1.0 : 0.55
        offsetXValueLabel.alpha = offsetEnabled ? 1.0 : 0.62
        offsetYValueLabel.alpha = offsetEnabled ? 1.0 : 0.62
    }

    // MARK: - 动作

    @objc private func fontSizeSwitchChanged(_ sender: UISwitch) {
        settingsController?.delegate?.setSettingBoolValue(sender.isOn, forKey: HUDUserDefaultsKeyUsesCustomFontSize)
        updateEnabledState()
    }

    @objc private func offsetSwitchChanged(_ sender: UISwitch) {
        settingsController?.delegate?.setSettingBoolValue(sender.isOn, forKey: HUDUserDefaultsKeyUsesCustomOffset)
        updateEnabledState()
    }

    @objc private func fontSizeSliderChanged(_ sender: UISlider) {
        let value = (Double(sender.value) * 20).rounded() / 20   // 0.05 步进
        sender.value = Float(value)
        settingsController?.delegate?.setSettingNumberValue(value, forKey: HUDUserDefaultsKeyRealCustomFontSize)
        updateValueLabels()
    }

    @objc private func offsetXSliderChanged(_ sender: UISlider) {
        let value = Double(sender.value.rounded())               // 1 点步进
        sender.value = Float(value)
        settingsController?.delegate?.setSettingNumberValue(value, forKey: HUDUserDefaultsKeyRealCustomOffsetX)
        updateValueLabels()
    }

    @objc private func offsetYSliderChanged(_ sender: UISlider) {
        let value = Double(sender.value.rounded())
        sender.value = Float(value)
        settingsController?.delegate?.setSettingNumberValue(value, forKey: HUDUserDefaultsKeyRealCustomOffsetY)
        updateValueLabels()
    }

    @objc private func tapResetButton(_ sender: UIButton) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        settingsController?.delegate?.resetCustomFontAndOffset()
        applyValues(animated: true)
    }
}
