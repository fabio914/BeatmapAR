import UIKit
import SceneKit
import ARKit

import APAudioPlayer
import BeatmapLoader

final class SceneViewController: UIViewController {

    @IBOutlet private var sceneView: ARSCNView!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet private weak var slider: UISlider!

    private var lightSource: SCNLight?

    // MARK: - References
    private var referenceNode: SCNNode?
    private var blueBlockNode: SCNNode?
    private var blueAnyDirectionNode: SCNNode?
    private var redBlockNode: SCNNode?
    private var redAnyDirectionNode: SCNNode?
    private var bombNode: SCNNode?

    private var rootNode: SCNNode?
    private let rootOriginPosition = SCNVector3(-0.375, -0.375, -1.0)

    private let duration: TimeInterval
    private let songDifficulty: BeatmapSongDifficulty
    private let distancePerSecond: Double
    private let audioPlayer: APAudioPlayer

    private var first = true
    var lastPauseTimestamp: TimeInterval?

    private var timeSetByUser: TimeInterval = 0 {
        didSet {
            lastPauseTimestamp = nil
            updateScene(for: timeSetByUser)
        }
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }

    init(
        duration: TimeInterval,
        bpm: UInt,
        songDifficulty: BeatmapSongDifficulty,
        audioPlayer: APAudioPlayer
    ) {
        self.duration = duration
        self.songDifficulty = songDifficulty
        self.audioPlayer = audioPlayer

        let distancePerBeat = 5.0
        let beatsPerSecond = Double(bpm)/60.0
        self.distancePerSecond =  distancePerBeat * beatsPerSecond

        super.init(nibName: String(describing: type(of: self)), bundle: Bundle(for: type(of: self)))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.scene = SCNScene(named: "art.scnassets/Scene.scn")!

        let light = SCNLight()
        light.type = .omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = .init(0, 2, 1)
        sceneView.pointOfView?.addChildNode(lightNode)
        self.lightSource = light

        self.referenceNode = sceneView.scene.rootNode.childNode(withName: "Reference", recursively: false)
        self.blueBlockNode = referenceNode?.childNode(withName: "Blue", recursively: false)
        self.blueAnyDirectionNode = referenceNode?.childNode(withName: "Blue Any Direction", recursively: false)
        self.redBlockNode = referenceNode?.childNode(withName: "Red", recursively: false)
        self.redAnyDirectionNode = referenceNode?.childNode(withName: "Red Any Direction", recursively: false)
        self.bombNode = referenceNode?.childNode(withName: "Bomb", recursively: false)
        referenceNode?.isHidden = true

        buildScene()
        updateScene(for: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        configuration.isLightEstimationEnabled = true

//        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
//            configuration.frameSemantics.insert(.personSegmentationWithDepth)
//        }

        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if first {
            audioPlayer.position = 0
            audioPlayer.play()
            first = false
        }
    }

    // MARK: - Helpers

    private func updateLightNodesLightEstimation() {
        DispatchQueue.main.async {
            guard let lightEstimate = self.sceneView.session.currentFrame?.lightEstimate else { return }

            let ambientIntensity = lightEstimate.ambientIntensity
            let ambientColorTemperature = lightEstimate.ambientColorTemperature

            self.lightSource?.intensity = ambientIntensity
            self.lightSource?.temperature = ambientColorTemperature
        }
    }

    // FIXME: Build the scene incrementally
    private func buildScene() {

        let rootNode = SCNNode()
        rootNode.position = rootOriginPosition

        for noteEvent in songDifficulty.notes {
            let noteNode: SCNNode? = {
                switch noteEvent.note {
                case .blueBlock(.anyDirection):
                    return blueAnyDirectionNode?.clone()
                case .blueBlock:
                    return blueBlockNode?.clone()
                case .redBlock(.anyDirection):
                    return redAnyDirectionNode?.clone()
                case .redBlock:
                    return redBlockNode?.clone()
                case .bomb:
                    return bombNode?.clone()
                }
            }()

            let direction: BeatmapDirection? = {
                switch noteEvent.note {
                case .blueBlock(let direction):
                    return direction
                case .redBlock(let direction):
                    return direction
                default:
                    return nil
                }
            }()

            guard let objectNode = noteNode else { continue }
            let coordinates = noteEvent.coordinates
            let noteTime = noteEvent.time

            objectNode.position = .init(
                Double(coordinates.column.rawValue) * 0.25,
                Double(coordinates.row.rawValue) * 0.25,
                -(noteTime * distancePerSecond)
            )

            let rotation = (direction?.angle ?? 0.0) * .pi/180.0
            objectNode.eulerAngles.z = rotation

            objectNode.isHidden = true
            rootNode.addChildNode(objectNode)
        }

        // TODO: Add obstacles

        sceneView.scene.rootNode.addChildNode(rootNode)
        self.rootNode = rootNode
    }

    private func updateScene(for time: TimeInterval) {
        let time = min(time, duration)
        let relativePosition = (time/duration)
        timeLabel.text = time.formatted
        slider.value = Float(relativePosition)
        rootNode?.position.z = Float(time * distancePerSecond) + rootOriginPosition.z
        audioPlayer.position = CGFloat(relativePosition)

        // Consider using `vibibleBeats` (and converting to `visibleSeconds`)
        let visibleSeconds = 4.0 // Reduce this value to increase the fps
        let visibleDistance = visibleSeconds * distancePerSecond
        let visibleDistanceSquared = Float(visibleDistance * visibleDistance)

        // This logic won't work well for walls....
        guard let cameraPosition = sceneView.pointOfView?.worldPosition else { return }

        // Consider using a different data structure to speed this up...
        rootNode?.childNodes.forEach({ $0.isHidden = (cameraPosition - $0.worldPosition).distanceSquared > visibleDistanceSquared })

        // Consider using https://developer.apple.com/documentation/scenekit/scnscenerenderer/1522647-isnode
    }

    // MARK: - Actions

    @IBAction func closeAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        timeSetByUser = Double(sender.value) * duration
    }
}

// MARK: - ARSCNViewDelegate

extension SceneViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        updateLightNodesLightEstimation()

        if lastPauseTimestamp == nil {
            lastPauseTimestamp = time - timeSetByUser
        }

        DispatchQueue.main.async {
            guard let lastPauseTimestamp = self.lastPauseTimestamp else { return }
            self.updateScene(for: time - lastPauseTimestamp)
        }
    }

//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//        let node = SCNNode()
//
//        return node
//    }

    func session(_ session: ARSession, didFailWithError error: Error) {
    }

    func sessionWasInterrupted(_ session: ARSession) {
    }

    func sessionInterruptionEnded(_ session: ARSession) {
    }
}

extension SCNVector3 {

    var distanceSquared: Float {
        x * x + y * y + z * z
    }

    static func - (lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        .init(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }
}
