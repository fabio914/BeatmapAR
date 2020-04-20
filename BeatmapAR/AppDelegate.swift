import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let backgroundDownloadQueue = DispatchQueue(label: "DownloadQueue", qos: .background)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        window.rootViewController = SongsViewController()
        window.makeKeyAndVisible()
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        let manager = FileManager.default
        guard let documentsURL = manager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }

        if url.scheme == "beatsaver",
            let beatSaverId = url.host,
            let downloadURL = URL(string: "https://beatsaver.com/api/download/key/\(beatSaverId)") {

            // FIXME: Display a download screen instead...
            backgroundDownloadQueue.async {
                if let beatmapData = try? Data(contentsOf: downloadURL) {
                    try? beatmapData.write(
                        to: documentsURL.appendingPathComponent("\(beatSaverId).zip"),
                        options: .atomicWrite
                    )
                }
            }

            return true
        } else if url.isFileURL {
            try? manager.moveItem(
                at: url,
                to: documentsURL.appendingPathComponent(url.lastPathComponent)
            )

            return true
        } else {
            return false
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }
}
