import UIKit
import SceneKit
import ARKit

import APAudioPlayer
import BeatmapLoader

final class SceneViewController: UIViewController {

    override var prefersStatusBarHidden: Bool {
        true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }

    // MARK: - Outlets
    @IBOutlet private var sceneView: ARSCNView!
    @IBOutlet private weak var timeLabel: UILabel!
    @IBOutlet weak var pauseLabel: UILabel!
    @IBOutlet private weak var slider: UISlider!

    // MARK: - Scene references
    private var referenceNode: SCNNode?
    private var blueBlockNode: SCNNode?
    private var blueAnyDirectionNode: SCNNode?
    private var redBlockNode: SCNNode?
    private var redAnyDirectionNode: SCNNode?
    private var bombNode: SCNNode?
    private var lineNode: SCNNode?

    // MARK: - Scene objects
    private var lightSource: SCNLight?
    private var rootNode: SCNNode?

    // MARK: - Parameters
    private let rootOriginPosition = SCNVector3(-0.375, -0.25, -1.0)
    private let lightPosition = SCNVector3(0, 1.5, 0.5)
    private let visibleSeconds = 1.5
    private let distancePerBeat = 4.0
    private let numberOfUpdatesBetweenAudioSyncs = 30

    // MARK: - Constants
    private let duration: TimeInterval
    private let songDifficulty: BeatmapSongDifficulty
    private let distancePerSecond: Double
    private let audioPlayer: APAudioPlayer

    // MARK: - Variables
    private var first = true
    private var initialSceneTimestamp: TimeInterval?
    private var audioSyncCount = 0

    private var timeSetByUser: TimeInterval = 0 {
        didSet {
            isPaused = true
            pausedSongTime = timeSetByUser
            updateScene(for: timeSetByUser, forceSyncAudio: true)
        }
    }

    private var isPaused: Bool = true {
        didSet {
            if isPaused {
                pauseLabel.text = "PLAY"
                audioPlayer.pause()
                initialSceneTimestamp = nil
                pausedSongTime = currentSongTime
            } else {
                pauseLabel.text = "PAUSE"
                // Forces an audio sync on the next frame
                audioSyncCount = numberOfUpdatesBetweenAudioSyncs
                audioPlayer.play()
            }
        }
    }

    private var pausedSongTime: TimeInterval = 0
    private var currentSongTime: TimeInterval = 0

    init(
        duration: TimeInterval,
        bpm: UInt,
        songDifficulty: BeatmapSongDifficulty,
        audioPlayer: APAudioPlayer
    ) {
        self.duration = duration
        self.songDifficulty = songDifficulty
        self.audioPlayer = audioPlayer

        let beatsPerSecond = Double(bpm)/60.0
        self.distancePerSecond =  distancePerBeat * beatsPerSecond

        super.init(nibName: String(describing: type(of: self)), bundle: Bundle(for: type(of: self)))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buildScene()
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
            updateScene(for: 0, forceSyncAudio: true)
            rootNode?.isHidden = false
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

    private func buildScene() {
        sceneView.delegate = self
        sceneView.scene = SCNScene(named: "art.scnassets/Scene.scn")!

        let light = SCNLight()
        light.type = .omni
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = lightPosition
        sceneView.pointOfView?.addChildNode(lightNode)
        self.lightSource = light

        loadSceneReferences()
        buildMap()
    }

    private func loadSceneReferences() {
        self.referenceNode = sceneView.scene.rootNode.childNode(withName: "Reference", recursively: false)
        self.blueBlockNode = referenceNode?.childNode(withName: "Blue", recursively: false)
        self.blueAnyDirectionNode = referenceNode?.childNode(withName: "Blue Any Direction", recursively: false)
        self.redBlockNode = referenceNode?.childNode(withName: "Red", recursively: false)
        self.redAnyDirectionNode = referenceNode?.childNode(withName: "Red Any Direction", recursively: false)
        self.bombNode = referenceNode?.childNode(withName: "Bomb", recursively: false)
        self.lineNode = referenceNode?.childNode(withName: "Line", recursively: false)
        referenceNode?.isHidden = true
    }

    // Consider building the map incrementally
    private func buildMap() {

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

        rootNode.isHidden = true
        sceneView.scene.rootNode.addChildNode(rootNode)
        self.rootNode = rootNode

        if let lineNode = lineNode?.clone() {
            lineNode.position = .init(0, rootOriginPosition.y - 0.125, rootOriginPosition.z)
            sceneView.scene.rootNode.addChildNode(lineNode)
        }
    }

    private func updateScene(for time: TimeInterval, forceSyncAudio: Bool = false) {
        self.currentSongTime = time
        let time = min(time, duration)
        let relativePosition = (time/duration)
        timeLabel.text = time.formatted
        slider.value = Float(relativePosition)
        rootNode?.position.z = Float(time * distancePerSecond) + rootOriginPosition.z

        audioSyncCount += 1

        if forceSyncAudio || (audioSyncCount >= numberOfUpdatesBetweenAudioSyncs) {
            audioPlayer.position = CGFloat(relativePosition)
            audioSyncCount = 0
        }

        let visibleDistance = visibleSeconds * distancePerSecond
        let visibleDistanceSquared = Float(visibleDistance * visibleDistance)

        // This logic won't work well for walls....
        guard let cameraPosition = sceneView.pointOfView?.worldPosition else { return }

        // Consider using a different data structure to speed this up...
        rootNode?.childNodes.forEach({ $0.isHidden = (cameraPosition - $0.worldPosition).distanceSquared > visibleDistanceSquared })

        // Consider using https://developer.apple.com/documentation/scenekit/scnscenerenderer/1522647-isnode
    }
}

// MARK: - Actions

extension SceneViewController {

    @IBAction private func closeAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction private func sliderValueChanged(_ sender: UISlider) {
        timeSetByUser = Double(sender.value) * duration
    }

    @IBAction private func pauseAction(_ sender: Any) {
        isPaused = !isPaused
    }
}

// MARK: - ARSCNViewDelegate

extension SceneViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        updateLightNodesLightEstimation()

        guard !isPaused else { return }

        if initialSceneTimestamp == nil {
            initialSceneTimestamp = time - pausedSongTime
        }

        DispatchQueue.main.async {
            guard let initialSceneTimestamp = self.initialSceneTimestamp else { return }
            self.updateScene(for: time - initialSceneTimestamp)
        }
    }

//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//    }
//
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
//    }

    func session(_ session: ARSession, didFailWithError error: Error) {
    }

    func sessionWasInterrupted(_ session: ARSession) {
    }

    func sessionInterruptionEnded(_ session: ARSession) {
    }
}
