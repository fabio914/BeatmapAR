import UIKit
import SceneKit
import ARKit

import BeatmapLoader

final class SceneViewController: UIViewController {

    @IBOutlet private var sceneView: ARSCNView!
    @IBOutlet private weak var timeLabel: UILabel!

    private var lightSource: SCNLight?

    // MARK: - References
    private var referenceNode: SCNNode?
    private var blueBlockNode: SCNNode?
    private var blueAnyDirectionNode: SCNNode?
    private var redBlockNode: SCNNode?
    private var redAnyDirectionNode: SCNNode?
    private var bombNode: SCNNode?

    private var rootNode: SCNNode?

    private let duration: TimeInterval
    private let songDifficulty: BeatmapSongDifficulty
    private let distancePerSecond: Double

    private var currentTime: TimeInterval = 0 {
        didSet {
            updateScene(for: currentTime)
        }
    }

    override var prefersStatusBarHidden: Bool {
        true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        true
    }

    init(duration: TimeInterval, bpm: UInt, songDifficulty: BeatmapSongDifficulty) {
        self.duration = duration
        self.songDifficulty = songDifficulty

        let distancePerBeat = 2.0
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
        lightNode.position = .init(0, 2, -1)
        sceneView.pointOfView?.addChildNode(lightNode)
        self.lightSource = light

        self.referenceNode = sceneView.scene.rootNode.childNode(withName: "Reference", recursively: false)
        self.blueBlockNode = referenceNode?.childNode(withName: "Blue", recursively: false)
        self.blueAnyDirectionNode = referenceNode?.childNode(withName: "Blue Any Direction", recursively: false)
        self.redBlockNode = referenceNode?.childNode(withName: "Red", recursively: false)
        self.redAnyDirectionNode = referenceNode?.childNode(withName: "Red Any Direction", recursively: false)
        self.bombNode = referenceNode?.childNode(withName: "Bomb", recursively: false)

        referenceNode?.isHidden = true

        let root = SCNNode()
        root.position = .init(-0.375, -0.375, -0.375)
        sceneView.scene.rootNode.addChildNode(root)
        self.rootNode = root

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

    // FIXME: This is not really efficient....
    private func updateScene(for time: TimeInterval) {
        timeLabel.text = time.formatted

        rootNode?.enumerateChildNodes({ node, _ in node.removeFromParentNode() })
        let mapSlice = songDifficulty.slice(for: (time - 1.0) ... (time + 9.0)) // 10 second slice

        for noteEvent in mapSlice.notes {
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
                -((noteTime - time) * distancePerSecond)
            )

            let rotation = (direction?.angle ?? 0.0) * .pi/180.0
            objectNode.eulerAngles.z = rotation

            rootNode?.addChildNode(objectNode)
        }

        // TODO: Draw obstacles
    }

    // MARK: - Actions

    @IBAction func closeAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        currentTime = Double(sender.value) * duration
    }
}

// MARK: - ARSCNViewDelegate

extension SceneViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        updateLightNodesLightEstimation()
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