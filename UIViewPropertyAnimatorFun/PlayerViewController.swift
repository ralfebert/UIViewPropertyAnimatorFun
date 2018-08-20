import UIKit

enum PlayerState {
    case thumbnail
    case fullscreen
}

class PlayerViewController: UIViewController {

    @IBOutlet private var playerView: UIView!
    private var playerViewAnimator: UIViewPropertyAnimator?
    private var originalPlayerViewFrame = CGRect.zero
    private var playerState = PlayerState.thumbnail
    private var panGestureRecognizer: UIPanGestureRecognizer?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan))
        view.addGestureRecognizer(self.panGestureRecognizer!)
    }

    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: view.superview)
        switch recognizer.state {
            case .began:
                self.panningBegan()
            case .changed:
                let translation = recognizer.translation(in: view.superview)
                panningChanged(withTranslation: translation)
            case .ended:
                let velocity = recognizer.velocity(in: view)
                panningEnded(withTranslation: translation, velocity: velocity)
            default:
                break // ignore
        }
    }

    func panningBegan() {
        var targetFrame : CGRect
        switch self.playerState {
            case .thumbnail:
                self.originalPlayerViewFrame = self.playerView.frame
                targetFrame = view.frame
            case .fullscreen:
                targetFrame = self.originalPlayerViewFrame
        }
        self.playerViewAnimator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.8, animations: {
            self.playerView.frame = targetFrame
        })
    }

    func panningChanged(withTranslation translation: CGPoint) {
        guard let animator = self.playerViewAnimator else { return }
        let translatedY = view.center.y + translation.y
        var progress: CGFloat
        switch self.playerState {
            case .thumbnail:
                progress = 1 - (translatedY / view.center.y)
            case .fullscreen:
                progress = (translatedY / view.center.y) - 1
        }
        progress = max(0.001, min(0.999, progress))
        animator.fractionComplete = progress
    }

    func panningEnded(withTranslation translation: CGPoint, velocity: CGPoint) {
        self.panGestureRecognizer?.isEnabled = false
        let screenHeight = UIScreen.main.bounds.size.height

        switch self.playerState {
            case .thumbnail:
                if translation.y <= -screenHeight / 3 || velocity.y <= -100 {
                    self.playerViewAnimator?.isReversed = false
                    self.playerViewAnimator?.addCompletion { [weak self] _ in
                        self?.playerState = .fullscreen
                        self?.panGestureRecognizer?.isEnabled = true
                    }
                } else {
                    self.playerViewAnimator?.isReversed = true
                    self.playerViewAnimator?.addCompletion { [weak self] _ in
                        self?.playerState = .thumbnail
                        self?.panGestureRecognizer?.isEnabled = true
                    }
                }
            case .fullscreen:
                if translation.y >= screenHeight / 3 || velocity.y >= 100 {
                    self.playerViewAnimator?.isReversed = false

                    self.playerViewAnimator?.addCompletion { [weak self] _ in
                        self?.playerState = .thumbnail
                        self?.panGestureRecognizer?.isEnabled = true
                    }
                } else {
                    self.playerViewAnimator?.isReversed = true
                    self.playerViewAnimator?.addCompletion { [weak self] _ in
                        self?.playerState = .fullscreen
                        self?.panGestureRecognizer?.isEnabled = true
                    }
                }
        }
        let velocityVector = CGVector(dx: velocity.x / 100, dy: velocity.y / 100)
        let springParameters = UISpringTimingParameters(dampingRatio: 0.8, initialVelocity: velocityVector)
        playerViewAnimator?.continueAnimation(withTimingParameters: springParameters, durationFactor: 1.0)
    }
}
