import UIKit

class CrosshairView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.clear
        isUserInteractionEnabled = false
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let centerX = rect.midX
        let centerY = rect.midY
        let crosshairSize: CGFloat = 20
        let lineWidth: CGFloat = 2
        
        context.setStrokeColor(TreeShopTheme.primaryGreen.cgColor)
        context.setLineWidth(lineWidth)
        
        // Draw horizontal line
        context.move(to: CGPoint(x: centerX - crosshairSize, y: centerY))
        context.addLine(to: CGPoint(x: centerX + crosshairSize, y: centerY))
        
        // Draw vertical line
        context.move(to: CGPoint(x: centerX, y: centerY - crosshairSize))
        context.addLine(to: CGPoint(x: centerX, y: centerY + crosshairSize))
        
        context.strokePath()
        
        // Draw center circle
        context.setStrokeColor(TreeShopTheme.primaryGreen.cgColor)
        context.setFillColor(UIColor.clear.cgColor)
        context.setLineWidth(1)
        
        let circleRect = CGRect(
            x: centerX - 3,
            y: centerY - 3,
            width: 6,
            height: 6
        )
        context.strokeEllipse(in: circleRect)
    }
    
    func show() {
        isHidden = false
        alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0
        } completion: { _ in
            self.isHidden = true
        }
    }
}