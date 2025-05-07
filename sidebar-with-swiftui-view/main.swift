import Cocoa
import SwiftUI

class WindowConfig {
    static let width: CGFloat = 659
    static let height: CGFloat = 400
    static let sidebarFixedWidth: CGFloat = 215
    static let sideBarTopPadding: CGFloat = 43
}

enum SidebarItem: String, CaseIterable {
    case shortcut = "Shortcut"
    case appearance = "Appearance"
    
    var icon: NSImageView {
        let imageName = "\(self.rawValue)-icon"
        let image = NSImage(named: NSImage.Name(imageName)) ?? NSImage()
        return NSImageView(image: image)
    }
    
    var viewController: NSViewController {
        switch self {
        case .shortcut:
            return ShortcutViewController()
        case .appearance:
            return AppearanceViewController()
        }
    }
}

protocol SidebarSelectionDelegate: AnyObject {
    func didSelectSidebarItem(_ item: SidebarItem)
}

class DraggableView: NSView {
    override public func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}

class SidebarViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    weak var delegate: SidebarSelectionDelegate?
    
    private let tableView = NSTableView()
    private let items = SidebarItem.allCases

    override func loadView() {
        self.view = NSView()

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Column"))
        tableView.addTableColumn(column)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 28
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.focusRingType = .none
        
        DispatchQueue.main.async {
            self.tableView.selectRowIndexes([0], byExtendingSelection: false)
        }
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: WindowConfig.sideBarTopPadding),
        ])
        
        let draggableView = DraggableView()
        draggableView.translatesAutoresizingMaskIntoConstraints = false
        draggableView.wantsLayer = true
        view.addSubview(draggableView)
        NSLayoutConstraint.activate([
            draggableView.heightAnchor.constraint(equalToConstant: WindowConfig.sideBarTopPadding + 10),
            draggableView.widthAnchor.constraint(equalToConstant: WindowConfig.sidebarFixedWidth),
            draggableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
        ])
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let textLabel = NSTextField(labelWithString: items[row].rawValue)
        let imageView = items[row].icon
        
        let stackView = NSStackView(views: [imageView, textLabel])
        stackView.spacing = 5
        stackView.heightAnchor.constraint(equalToConstant: tableView.rowHeight).isActive = true
        
        return stackView
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedIndex = tableView.selectedRow
        guard selectedIndex >= 0 else { return }
        delegate?.didSelectSidebarItem(items[selectedIndex])
    }
}

class SettingsView: NSView {
    let rootView: AnyView

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame frameRect: NSRect) {
        fatalError("Use init(view:) instead")
    }

    init<V: View>(view: V) {
        self.rootView = AnyView(view)
        super.init(frame: .zero)
        setupView()
    }

    private func setupView() {
        let hostingView = NSHostingView(rootView: rootView)
        addSubview(hostingView)

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

struct ShortcutSettingsView: View {
    
    var body: some View {
        VStack {
            Text("Shortcut Settings")
        }
        .frame(minWidth: 400, minHeight: 400)
    }
}

struct AppearanceSettingsView: View {
    
    var body: some View {
        VStack {
            Text("Appearance Settings")
        }
        .frame(minWidth: 400, minHeight: 500)
    }
}

class ShortcutViewController: NSViewController {
    override func loadView() {
        self.view = SettingsView(view: ShortcutSettingsView())
    }
}

class AppearanceViewController: NSViewController {
    override func loadView() {
        self.view = SettingsView(view: AppearanceSettingsView())
    }
}

class SplitViewController: NSSplitViewController, SidebarSelectionDelegate {
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: WindowConfig.width, height: WindowConfig.height))
        super.loadView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let sidebarVC = SidebarViewController()
        sidebarVC.delegate = self

        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarVC)
        sidebarItem.minimumThickness = WindowConfig.sidebarFixedWidth
        sidebarItem.maximumThickness = WindowConfig.sidebarFixedWidth
        sidebarItem.canCollapse = false
        addSplitViewItem(sidebarItem)
        
        let detailItem = NSSplitViewItem(viewController: SidebarItem.shortcut.viewController)
        addSplitViewItem(detailItem)
    }

    func didSelectSidebarItem(_ item: SidebarItem) {
        removeSplitViewItem(splitViewItems[1])
        let newDetailItem = NSSplitViewItem(viewController: item.viewController)
        addSplitViewItem(newDetailItem)
    }
}

var mainWindow: NSWindow?

func addPaddingToWindowButtons(leading: CGFloat, top: CGFloat) {
    DispatchQueue.main.async {
        mainWindow?.standardWindowButton(.miniaturizeButton)?.frame.origin.y -= top
        mainWindow?.standardWindowButton(.closeButton)?.frame.origin.y -= top
        mainWindow?.standardWindowButton(.zoomButton)?.frame.origin.y -= top
        
        mainWindow?.standardWindowButton(.miniaturizeButton)?.frame.origin.x += leading
        mainWindow?.standardWindowButton(.closeButton)?.frame.origin.x += leading
        mainWindow?.standardWindowButton(.zoomButton)?.frame.origin.x += leading
        
        let buttonContainer = mainWindow?.standardWindowButton(.closeButton)?.superview
        
        for subview in buttonContainer?.subviews ?? [] where subview is NSTextField {
            subview.frame.origin.y -= top
        }
    }
}

func createMainWindow() {
    mainWindow = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: WindowConfig.width, height: WindowConfig.height),
        styleMask: [.titled, .closable, .fullSizeContentView],
        backing: .buffered, defer: false
    )
    mainWindow?.center()
    mainWindow?.contentViewController = SplitViewController()
    mainWindow?.titlebarAppearsTransparent = true
    
    mainWindow?.title = "Settings"
    
    addPaddingToWindowButtons(leading: 12, top: 12)
    
    /// hack to increase draggable titlebar area
    mainWindow?.addTitlebarAccessoryViewController(NSTitlebarAccessoryViewController())
    
    let _ = NSWindowController(window: mainWindow)
    
    mainWindow?.makeKeyAndOrderFront(nil)
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createMainWindow()
        
        mainWindow?.makeKeyAndOrderFront(nil)
    }
}

let app = Application.shared
let delegate = AppDelegate()
app.delegate = delegate

app.run()

#Preview {
    SplitViewController()
}
