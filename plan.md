# TouchDeck Plan

## 1. Product Vision

TouchDeck la mot ung dung macOS bien Touch Bar tren MacBook Pro thanh mot bang dieu khien tuy bien, tuong tu Stream Deck nhung duoc thiet ke rieng cho Touch Bar.

Ung dung gom hai phan chinh:

- TouchDeck Runtime: chay nen, giu Global Touch Bar, render layout nguoi dung da cau hinh va xu ly thao tac o moi app.
- TouchDeck Studio: giao dien cau hinh tren man hinh, co Touch Bar ao de keo tha, sap xep, resize va gan chuc nang cho tung nut.

Muc tieu cua san pham:

- Thay the trai nghiem Touch Bar mac dinh bang mot layout huu ich hon.
- Hien thi va hoat dong o moi app, ke ca khi TouchDeck khong phai app dang active.
- Cho phep nguoi dung tao bo nut rieng theo workflow ca nhan.
- Tro thanh mini Dock, launcher, shortcut panel va status dashboard tren Touch Bar.
- Giu trai nghiem sang trong, toi gian, premium va dung tinh than macOS.

Quyet dinh san pham moi:

- TouchDeck phai uu tien che do Global Touch Bar, tuc la layout cua TouchDeck van nam tren Touch Bar khi nguoi dung dang dung Finder, Xcode, Safari, Photoshop hoac bat ky app nao khac.
- Che do public `NSTouchBar` chi dung lam fallback/dev mode, vi macOS public API mac dinh chi gan Touch Bar voi app dang active.
- Neu muon dat trai nghiem giong MTMR, app can co lop runtime rieng dung ky thuat system/global presentation. Lop nay co the can private API/undocumented API va phai duoc tach rieng, co canh bao ro trong UI.
- San pham khong dat muc "chay duoc" neu Touch Bar chi hien khi TouchDeck active.

## 2. Core Features

### 2.1 Virtual Touch Bar Editor

TouchDeck Studio se co mot Touch Bar ao hien thi tren man hinh. Nguoi dung co the keo cac nut chuc nang tu thu vien vao Touch Bar ao, keo ra de xoa, sap xep lai vi tri va thay doi kich co.

Tinh nang can co:

- Touch Bar ao co ti le gan voi Touch Bar that.
- Chia layout thanh cac o logic.
- Ho tro drag and drop.
- Ho tro reorder.
- Ho tro remove bang cach keo ra khoi Touch Bar ao hoac bam delete.
- Ho tro resize nut: 1 o, 2 o, 3 o.
- Preview trang thai nut ngay trong editor.
- Chon nut de mo inspector.
- Luu layout thanh profile.
- Render Touch Bar that theo dung layout da luu.

Bo cuc man hinh de xuat:

```text
┌──────────────────────────────────────────────────────────────┐
│ TouchDeck                                                    │
├────────────────┬─────────────────────────────────────────────┤
│ Sidebar        │ Main Editor                                 │
│                │                                             │
│ Profiles       │ Virtual Touch Bar                           │
│ Library        │ ┌─────────────────────────────────────────┐ │
│ System         │ │ [App] [Copy] [Paste] [RAM] [Weather]   │ │
│ Apps           │ └─────────────────────────────────────────┘ │
│ Functions      │                                             │
│ Widgets        │ Inspector                                   │
└────────────────┴─────────────────────────────────────────────┘
```

### 2.1.1 Global Touch Bar Runtime

Day la yeu cau cot loi de app giong Stream Deck/MTMR thay vi chi la demo `NSTouchBar`.

Hanh vi bat buoc:

- TouchDeck chay nen sau khi mo app hoac launch at login.
- Layout cua TouchDeck luon hien tren Touch Bar khi nguoi dung chuyen sang app khac.
- App khac dang active van nhan keyboard/mouse focus binh thuong.
- Cham nut tren Touch Bar van goi action cua TouchDeck.
- Khi TouchDeck Studio dang mo, nguoi dung co the edit layout ma runtime van tiep tuc cap nhat Touch Bar that.
- Neu runtime global loi hoac khong duoc ho tro tren may/macOS hien tai, app phai hien trang thai ro rang va co fallback sang App-Active Mode.

Kien truc runtime:

- `TouchBarRenderer`: chi tao `NSTouchBar` va item views tu profile.
- `GlobalTouchBarPresenter`: dua `NSTouchBar` cua TouchDeck len Touch Bar o muc global/system modal.
- `AppActiveTouchBarPresenter`: fallback dung public AppKit, chi hien khi TouchDeck active.
- `TouchBarRuntimeCoordinator`: chon presenter phu hop, restart presenter khi profile doi, macOS sleep/wake, app relaunch hoac Touch Bar service reset.
- `RuntimeStatusStore`: bao trang thai cho Studio:
  - Global Active.
  - Global Unsupported.
  - Permission Missing.
  - Fallback App-Active.
  - Runtime Error.

Nguyen tac:

- Global mode la default cua san pham.
- Public app-active mode chi dung de debug, fallback va nhung may/macOS khong ho tro.
- Private/undocumented API phai duoc boc trong mot module rieng, de core model/editor khong phu thuoc truc tiep.
- Global presenter nen uu tien selector co `placement = 1` de thay toan bo Touch Bar; selector khong co `placement` co the lam layout bi render trong vung qua hep va sinh canh bao `too large`/`not enough space`.
- Touch Bar runtime nen render thanh nhieu `NSTouchBarItem` nho theo layout thay vi mot canvas lon duy nhat, de AppKit co the tinh kich thuoc item dung hon.
- UI phai co Experimental/Compatibility notice, vi global Touch Bar co the khong App Store-safe va co the bi anh huong khi macOS update.

### 2.2 System Buttons

App can ho tro cac nut co tren Touch Bar goc hoac mo phong lai hanh vi cua chung.

Nhom system button du kien:

- Escape.
- Volume up.
- Volume down.
- Mute.
- Brightness up.
- Brightness down.
- Keyboard brightness, neu may va macOS ho tro.
- Play/pause.
- Next track.
- Previous track.
- Mission Control.
- Launchpad.
- Screenshot full screen (`Command + Shift + 3`).
- Screenshot selection (`Command + Shift + 4`).
- Dictation.
- Emoji picker.
- Siri, neu kha thi.
- Lock screen.
- Sleep.
- Focus/Do Not Disturb, neu kha thi.
- Volume slider.
- Brightness slider.

Luu y ky thuat:

- Khong nen gia dinh co the nhung truc tiep nut goc cua Apple vao app.
- Nen thiet ke theo huong emulated system actions.
- Cac action don gian nhu copy, paste, emoji, lock screen, sleep, screenshot chi hien icon va chi co kich co 1 o.
- Slider control nhu volume/brightness dung kich co 3 o de thao tac chinh xac hon.
- Moi action can co trang thai support ro rang:
  - Supported.
  - Requires Accessibility permission.
  - Requires Automation permission.
  - Requires AppleScript/Shortcuts fallback.
  - Limited by macOS public API.

### 2.3 App Button

App Button bien Touch Bar thanh mini Dock cho cac app hay dung.

Hanh vi:

- Nguoi dung chon mot app da cai tren may.
- Touch Bar chi hien icon/logo cua app, khong hien ten app, text, badge, dot, running indicator hay active indicator.
- App Button chi co kich co 1 o trong MVP de giong Dock icon thu gon.
- Bam vao icon:
  - Neu app chua chay: launch app.
  - Neu app dang chay: activate app.
- Long press, giai doan sau:
  - Quit app.
  - Hide app.
  - Show windows.
  - Force quit, neu duoc cap quyen.

Gia tri cua feature:

- Mo nhanh app hay dung.
- Chuyen app nhanh hon Dock trong mot so workflow.
- Giu cac app quan trong luon nam tren Touch Bar.

Thong tin can luu:

```swift
struct AppButtonConfig: Codable {
    var appName: String
    var bundleIdentifier: String
    var appPath: String?
    var showRunningIndicator: Bool
    var showActiveIndicator: Bool
}
```

### 2.4 Function Button

Function Button la nut chuc nang co the gan action. Nut co nhieu kich co khac nhau, nhung kich co phai theo rule cua tung loai action:

- 1 o: action don gian, icon-only. Vi du: Copy, Paste, Cut, Undo, Redo, Select All, Hide, Quit.
- 2 o: action can label ngan hoac tham so da cau hinh.
- 3 o: action dai, co tham so, hoac can dien tich thao tac nhu shell/script/shortcut/slider.
- Neu action duoc dinh nghia la icon-only thi Studio khong duoc cho chon 2 o hoac 3 o.

Function mac dinh nen co trong MVP:

- Copy.
- Paste.
- Cut.
- Undo.
- Redo.
- Select All.
- Open URL.
- Open app.
- Open file/folder.
- Send keyboard shortcut.
- Run shell command.
- Run AppleScript.
- Run macOS Shortcut.
- Hide current app.
- Quit current app.
- Kill current app.

Huong mo rong:

- Tat ca function duoc dang ky qua Function Registry.
- Moi function co id on dinh de layout cu khong bi hong khi app update.
- Moi function co parameter schema de editor biet can hien field nao.
- Sau nay co the them function moi ma khong can doi format layout.

Protocol goi y:

```swift
protocol TouchDeckFunction {
    var id: String { get }
    var name: String { get }
    var icon: String { get }
    var supportedSizes: [ButtonSize] { get }
    var parametersSchema: FunctionParameterSchema { get }

    func run(context: ActionContext) async throws
}
```

Config goi y:

```swift
struct FunctionButtonConfig: Codable {
    var functionId: String
    var size: ButtonSize
    var parameters: [String: String]
}
```

### 2.5 Info / Widget Button

Widget Button hien thi thong so va cap nhat dinh ky.

Widget du kien:

- RAM usage.
- SSD usage.
- CPU usage.
- Battery.
- Network speed.
- Weather.
- Date/time.
- Current song.
- Active app.
- Focus mode.
- Server/dev status, giai doan sau.

Yeu cau:

- Widget khong lam Touch Bar bi lag.
- Co refresh interval rieng cho tung widget.
- Co cache snapshot moi nhat.
- Neu lay du lieu loi, hien state nhe nhang thay vi crash.
- Widget dang phan tram nhu RAM, SSD, CPU, Battery co 2 layout:
  - 1 o: icon nam phia duoi, phan tram su dung nam chong len phia tren.
  - 2 o: icon ben trai, phan tram ben phai.
- Widget dang phan tram khong can 3 o trong MVP.

Protocol goi y:

```swift
protocol TouchDeckWidget {
    var id: String { get }
    var name: String { get }
    var refreshInterval: TimeInterval { get }

    func snapshot() async throws -> WidgetSnapshot
}

struct WidgetSnapshot {
    var title: String
    var subtitle: String?
    var icon: String?
    var progress: Double?
    var colorHex: String?
}
```

## 3. Layout Model

Layout nen duoc thiet ke theo cell thay vi pixel de de render dong nhat giua Touch Bar ao va Touch Bar that.

Quy uoc kich thuoc:

- MVP dung capacity 17 o moi page de lap day gan tron vung Touch Bar that voi metrics hien tai.
- 1 o, 2 o, 3 o la cac kich thuoc co dinh, khong tinh tuy tien theo text.
- Moi o co width co dinh; nut 2 o va 3 o duoc tinh tu cell width cong spacing noi bo co dinh.
- Touch Bar that va Touch Bar ao co the dung scale khac nhau, nhung ty le 1/2/3 o phai dong nhat.
- Noi dung ben trong nut phai tu can chinh:
  - Nut 1 o: can giua, uu tien icon-only.
  - Nut 2 o: icon trai, text/so lieu phai, spacing ngan.
  - Nut 3 o: icon trai, noi dung chinh giua/phai, dung cho slider/action dai.
- Tat ca phim co nen mo/translucent nhu Touch Bar goc cua macOS, bo goc mem, border rat nhe, khong dung nen phang day mau.
- Tat ca nut/phim phai co bo goc va vien duoc thiet ke ro rang, mem, dong nhat; khong de nut vuong hoac vien mac dinh thieu tinh te.
- Noi dung ben trong nut phai co padding toi thieu an toan, khong duoc ap sat vien; text dai phai truncate/scale nhe thay vi tran ra mep.

```swift
enum ButtonSize: Int, Codable {
    case small = 1
    case medium = 2
    case large = 3
}

struct TouchBarLayout: Codable {
    var pages: [TouchBarPage]
}

struct TouchBarPage: Codable {
    var items: [TouchBarItemConfig]
}

struct TouchBarItemConfig: Codable {
    var id: UUID
    var position: Int
    var size: ButtonSize
    var type: TouchBarItemType
}

enum TouchBarItemType: Codable {
    case system(SystemButtonConfig)
    case app(AppButtonConfig)
    case function(FunctionButtonConfig)
    case widget(WidgetButtonConfig)
    case spacer
}
```

Can co validation:

- Khong cho item overlap.
- Khong cho tong so cell vuot qua do rong page.
- Tu dong snap vao grid.
- Neu drop vao vi tri khong hop le, hien preview invalid nhe nha.
- Cho phep spacer/flexible spacer de can layout.

## 4. Profiles

Profile cho phep nguoi dung co nhieu layout khac nhau.

Loai profile:

- Default profile.
- App-specific profile theo bundle identifier.
- Manual profile nguoi dung tu chuyen.
- Temporary profile, giai doan sau.

Hanh vi:

- Khi frontmost app thay doi, app kiem tra profile phu hop.
- Neu co profile rieng cho app do, Global Touch Bar doi sang profile do.
- Neu khong co, dung default profile.
- Nguoi dung co the khoa profile hien tai neu khong muon auto switch.
- Viec doi profile phai dien ra trong khi app khac van active, khong duoc keo focus ve TouchDeck.

## 5. Architecture

```text
TouchDeck
├── Runtime
│   ├── TouchBarRenderer
│   ├── GlobalTouchBarPresenter
│   ├── AppActiveTouchBarPresenter
│   ├── TouchBarRuntimeCoordinator
│   ├── TouchBarStateStore
│   ├── RuntimeStatusStore
│   ├── ActionDispatcher
│   ├── WidgetRefreshEngine
│   └── AppStateObserver
│
├── Studio
│   ├── VirtualTouchBarCanvas
│   ├── ButtonLibrary
│   ├── ButtonInspector
│   └── LayoutEditorStore
│
├── Core
│   ├── ProfileStore
│   ├── FunctionRegistry
│   ├── WidgetRegistry
│   ├── PermissionManager
│   └── IconProvider
│
└── Integrations
    ├── SystemActions
    ├── AppActions
    ├── KeyboardActions
    ├── ShellActions
    └── AppleScriptActions
```

### 5.1 Runtime

Runtime chiu trach nhiem render Touch Bar that va xu ly tuong tac.

Thanh phan:

- TouchBarRenderer: tao `NSTouchBar`, `NSTouchBarItem`, custom view cho nut.
- GlobalTouchBarPresenter: giu TouchDeck hien tren Touch Bar khi app khac active. Day la lop can nghien cuu/implement theo huong MTMR, co the dung private API/undocumented API.
- AppActiveTouchBarPresenter: fallback dung public AppKit, chi hien khi TouchDeck active.
- TouchBarRuntimeCoordinator: dieu phoi renderer/presenter, restart runtime khi profile doi, macOS sleep/wake, Touch Bar service reset hoac presenter loi.
- ActionDispatcher: nhan event tap/long press va chay action tuong ung.
- WidgetRefreshEngine: cap nhat widget snapshots.
- AppStateObserver: theo doi app launched, terminated, activated.
- TouchBarStateStore: giu state runtime hien tai.
- RuntimeStatusStore: dong bo trang thai runtime ve Studio de hien Global Active, Fallback, Missing Permission hoac Error.

Quyet dinh quan trong:

- Khong de `TouchBarRenderer` biet global/private API. Renderer chi tao view.
- Moi API rui ro cao nam trong `GlobalTouchBarPresenter`.
- Neu global presenter khong khoi dong duoc, runtime khong crash; app hien fallback va log loi.
- Khi TouchDeck Studio bi dong, Runtime van tiep tuc chay neu nguoi dung bat Launch at Login hoac menu bar runtime.

### 5.2 Studio

Studio chiu trach nhiem cau hinh layout.

Thanh phan:

- VirtualTouchBarCanvas: touch bar ao, drag/drop/reorder/resize.
- ButtonLibrary: danh sach system/app/function/widget co the them.
- ButtonInspector: chinh config cua item dang chon.
- LayoutEditorStore: state cua editor, dirty state, undo/redo.

### 5.3 Core

Core chua cac logic dung chung.

Thanh phan:

- ProfileStore: doc/ghi JSON profile.
- FunctionRegistry: dang ky cac function.
- WidgetRegistry: dang ky cac widget.
- PermissionManager: quan ly Accessibility, Automation, Location, Network permissions.
- IconProvider: lay icon app, system icon, custom icon.

## 6. Frontend / UI Design Direction

### 6.1 Design Role

Thiet ke giao dien theo mindset cua mot Senior UI/UX Designer cua Apple va mot Frontend Engineer nhieu kinh nghiem.

Ung dung can co cam giac giong cac ung dung chinh chu cua Apple:

- System Settings.
- Apple Music.
- Finder.
- Xcode.
- TestFlight.

Co the tham khao them tinh than cua:

- Raycast.
- Arc Browser.
- CleanShot X.
- Linear.
- Notion Calendar.

Tong the phai tao cam giac:

- Sang trong.
- Toi gian.
- Premium.
- Chuyen nghiep.
- Nhieu khoang trang.
- De doc.
- Khong roi mat.
- Co chieu sau nhe, nhung khong loe loet.

### 6.2 Visual Language

Nen:

- Nen trang nga hoac xam rat nhat.
- Card mau trang.
- Border rat manh.
- Shadow nhe.
- Radius vua phai, uu tien 8-12 px tuy platform.
- Text ro rang, uu tien SF Pro neu native macOS.
- Icon dong nhat, uu tien SF Symbols cho system icon.
- Dung spacing rong rai, co trat tu.
- Su dung motion nhe khi drag/drop, hover, selected, active.

Khong nen:

- Nen gradient tim/xanh dam kieu SaaS landing page.
- Card qua day, shadow qua nang.
- Qua nhieu mau nhan.
- Giao dien day dac nhu dashboard enterprise.
- Qua nhieu border long nhau.
- Text nho den muc kho doc.

Mau sac goi y:

```text
App background: #F5F5F7 or #F7F7F8
Surface/Card:   #FFFFFF
Border:         rgba(0, 0, 0, 0.08)
Shadow:         rgba(0, 0, 0, 0.06)
Primary text:   rgba(0, 0, 0, 0.88)
Secondary text: rgba(0, 0, 0, 0.56)
Tertiary text:  rgba(0, 0, 0, 0.36)
Accent:         macOS accent color
```

### 6.3 Main Window Layout

Main window nen di theo pattern macOS quen thuoc:

- Sidebar trai.
- Content chinh o giua.
- Inspector ben phai hoac panel duoi tuy kich thuoc window.
- Toolbar tren cung gon, co segmented control neu can doi view.

Bo cuc de xuat:

```text
┌────────────────────────────────────────────────────────────────────┐
│ Toolbar: TouchDeck        Profile: Default      Preview | Run       │
├───────────────┬─────────────────────────────────────┬──────────────┤
│ Sidebar       │ Editor                              │ Inspector    │
│               │                                     │              │
│ Profiles      │ Virtual Touch Bar                   │ Selected     │
│ Library       │                                     │ Item Config  │
│ System        │ Button Library / Canvas             │              │
│ Apps          │                                     │              │
│ Functions     │                                     │              │
│ Widgets       │                                     │              │
└───────────────┴─────────────────────────────────────┴──────────────┘
```

Sidebar:

- Rong vua phai.
- Nhom ro rang.
- Dung icon + label.
- Selected state giong Finder/System Settings.

Editor:

- La khu vuc co nhieu khoang trang nhat.
- Virtual Touch Bar nam o trung tam/gan tren.
- Co grid snap preview tinh te.
- Co empty state dep khi chua co item.

Inspector:

- Hien khi chon item.
- Gom cac control native:
  - Text field.
  - Picker.
  - Toggle.
  - Segmented control cho size.
  - Button chon app/icon.
  - Test action button.
- Khong nen bien inspector thanh mot form qua dai.

Runtime Status area:

- Nen nam trong toolbar hoac mot panel gon trong Settings/Permission Center.
- Hien trang thai ngan gon:
  - Global Active.
  - Starting.
  - Fallback App-Active.
  - Permission Missing.
  - Unsupported.
  - Error.
- Co nut Start/Stop Runtime.
- Co nut Open Compatibility Details.
- Khong chen vao luong edit chinh, nhung phai du de nguoi dung biet tai sao Touch Bar khong hien o app khac.

### 6.4 Virtual Touch Bar UI

Virtual Touch Bar la hero object cua app. No phai trong nhu mot vat the that, premium va de hieu.

Yeu cau:

- Nen den/xam dam nhu Touch Bar that.
- Bo tron pill shape.
- Co inner shadow nhe.
- Cac button nam ben trong co spacing deu.
- Button co state:
  - Normal.
  - Hover.
  - Selected.
  - Dragging.
  - Error.
- Moi button co nen mo/translucent nhu phim Touch Bar goc, bo goc nhe, stroke mong, noi dung can giua dep trong kich thuoc 1/2/3 o co dinh.
- Vien nut phai dep va co chu y: border mong, radius dong nhat, selected state dung accent stroke, khong lam UI bi nang.
- Icon/text trong nut phai nam trong vung content inset dong nhat; icon-only can giua tuyet doi, icon + text can giua theo cum va co trailing/leading inset.
- Khi drag item vao, hien ghost preview.
- Khi vi tri hop le, highlight nhe bang accent color.
- Khi vi tri khong hop le, dung red tint rat nhe.

App Button:

- Icon app chat luong cao.
- Chi hien logo/icon app, khong text, khong badge, khong running/active indicator.
- Chi co kich co 1 o.

Function Button:

- Co icon va label tuy kich co.
- 1 o uu tien icon.
- 2 o icon + short label.
- 3 o icon + label + optional state.
- Nen phim dung chung style translucent, khong moi loai mot nen rieng.

Widget Button:

- Co so lieu ro.
- Co the co mini progress bar/ring neu can.
- Khong update bang animation qua manh.

### 6.5 Interaction Design

Nguyen tac:

- Moi thao tac chinh co feedback ngay.
- Drag/drop phai muot va co snap ro rang.
- Undo/redo nen co tu giai doan editor on dinh.
- Khi xoa item, khong can modal neu co undo.
- Khi action can permission, hien prompt trong app truoc khi mo System Settings.

Interaction can co:

- Drag from library to virtual Touch Bar.
- Drag inside virtual Touch Bar to reorder.
- Drag out to remove.
- Click item to select.
- Double click item to quick edit.
- Right click/context menu:
  - Duplicate.
  - Delete.
  - Change size.
  - Test action.
- Keyboard support:
  - Delete to remove.
  - Command-Z undo.
  - Command-Shift-Z redo.
  - Arrow keys move selected item, giai doan sau.

### 6.6 Empty, Loading, Error States

Empty state:

- Khi layout trong: hien mot hint nhe trong Touch Bar ao.
- Vi du: "Drag buttons here".
- Khong dung doan text dai.

Loading state:

- App picker co loading skeleton nhe.
- Widget co placeholder gon.

Error state:

- Action loi: hien toast nho hoac inline status trong inspector.
- Permission thieu: hien card nho voi nut "Open System Settings".
- Widget loi: hien gia tri cu neu co, kem icon warning nhe.

### 6.7 Native macOS Feel

Nen uu tien:

- SwiftUI cho Studio UI neu phu hop.
- AppKit cho Touch Bar runtime.
- SF Symbols cho icon system.
- macOS accent color.
- Native controls thay vi custom qua muc.
- Toolbar va sidebar dung pattern quen thuoc cua macOS.

Neu dung SwiftUI:

- Dung `NavigationSplitView` cho sidebar/content/inspector.
- Dung `List`/`Section` cho sidebar.
- Dung `Form` mot cach tiet che trong inspector.
- Dung custom canvas cho Virtual Touch Bar.

## 7. Permissions

Can quan ly permission that ro vi app co nhieu action lien quan den he thong.

Permission du kien:

- Accessibility: gui phim tat, dieu khien app khac, kill/activate mot so workflow.
- Automation: AppleScript dieu khien app khac.
- Location: weather widget, neu dung location hien tai.
- Network: weather API.
- Launch at Login: giu TouchDeck Runtime tu chay sau khi dang nhap.
- Full Disk Access: tranh yeu cau neu khong that su can.

Nguyen tac:

- Chi xin permission khi can.
- Giai thich ngan gon vi sao can.
- Co man hinh Permission Center trong Settings.
- Neu nguoi dung tu choi, app van chay cac feature khong can permission.

## 8. Technical Risks

### 8.1 Global Touch Bar

Public Touch Bar API cua Apple chu yeu gan voi app dang active. Vi yeu cau san pham la TouchDeck phai hien o moi app, Global Touch Bar la rui ro ky thuat lon nhat va phai duoc xu ly som.

Hien trang:

- `NSTouchBar` public phu hop cho App-Active Mode, khong du de thay the Touch Bar toan he thong.
- Cac app nhu MTMR lam duoc vi chung di theo huong system/global presentation, kha nang cao co lien quan den API private/undocumented cua macOS.
- Huong nay khong App Store-safe, co the bi macOS update lam hong, va bat buoc test tren may Touch Bar that.

Huong xu ly:

- Uu tien prototype Global Touch Bar ngay trong Phase 1, khong de den cuoi.
- Nghien cuu MTMR source de xac dinh mechanism cu the:
  - Presenter/presentation API nao duoc goi.
  - Cach giu bar khi app khac active.
  - Cach reset/re-present khi app switch, sleep/wake, Control Strip thay doi.
- Implement `GlobalTouchBarPresenter` bang runtime lookup/selector guards de tranh hard crash khi API khong ton tai.
- Tach `GlobalTouchBarPresenter` thanh module rieng va co flag bat/tat.
- Tao `AppActiveTouchBarPresenter` lam fallback de app van dung duoc trong moi truong khong ho tro.
- Them Compatibility screen trong Studio:
  - macOS version.
  - Touch Bar detected.
  - Accessibility status.
  - Global presenter status.
  - Last runtime error.
- Log ro rang nhung khong lam UI bi roi.

Dieu kien pass:

- Mo TouchDeck, bam Launch at Login/Start Runtime.
- Chuyen sang Finder/Xcode/Safari, Touch Bar van hien layout TouchDeck.
- Tap App Button trong khi Finder/Xcode/Safari active van launch/activate app dung.
- Tap Copy/Paste/System action trong app khac van chay dung neu du permission.
- Dong Studio window, runtime van tiep tuc giu Touch Bar.
- Kill/restart TouchDeck runtime thi Touch Bar khoi phuc duoc.

### 8.2 System Buttons

Mot so nut goc cua Apple co the khong co public API truc tiep.

Huong xu ly:

- Implement theo compatibility matrix.
- Action nao lam duoc bang key event thi lam bang key event.
- Action nao can Shortcuts/AppleScript thi goi fallback.
- Action nao khong kha thi thi danh dau limited.

### 8.3 Performance

Touch Bar phai phan hoi nhanh.

Huong xu ly:

- Cache icon.
- Cache widget snapshot.
- Khong block main thread khi chay shell/API.
- Render button custom gon nhe.
- Gioi han refresh interval cua widget.

## 9. MVP Scope

MVP nen gom:

- Menu bar app.
- Background runtime.
- Global Touch Bar mode hien layout cua TouchDeck khi app khac active.
- Fallback App-Active Mode neu global mode khong ho tro.
- Runtime status/Compatibility panel.
- TouchDeck Studio window.
- Virtual Touch Bar editor.
- Drag/drop tu library vao Touch Bar ao.
- Reorder item.
- Resize 1/2/3 o.
- Luu/load layout JSON.
- Render layout len Touch Bar that.
- App Button:
  - Chon app.
  - Hien icon.
  - Running indicator.
  - Tap de launch/activate.
- Function Button:
  - Copy.
  - Paste.
  - Open URL.
  - Open app.
  - Keyboard shortcut.
- Widget Button:
  - RAM.
  - SSD.
- Permission Center co ban.

Chua can co trong MVP:

- Tat ca system button.
- Weather neu muon tranh API/location luc dau.
- Multi-window app switcher.
- Marketplace function.
- Cloud sync.
- Plugin system cho ben thu ba.
- App Store distribution, vi Global Touch Bar co kha nang dung API khong duoc Apple chap nhan.

## 10. Development Roadmap

### Phase 1: Feasibility Prototype

Muc tieu:

- Tao macOS app native.
- Render duoc custom Touch Bar bang public `NSTouchBar`.
- Implement prototype `GlobalTouchBarPresenter`.
- Xac minh TouchDeck co the hien tren Touch Bar khi Finder/Xcode/Safari dang active.
- Co 3 nut hardcoded:
  - App Button.
  - Copy/Paste Function Button.
  - RAM Widget.
- Tap nut chay action that.
- Xac minh gioi han public API va private/undocumented API.
- Tao fallback `AppActiveTouchBarPresenter`.
- Tao runtime status toi thieu:
  - Global Active.
  - Fallback App-Active.
  - Unsupported.
  - Error.

Ket qua:

- Co demo Touch Bar that chay khi TouchDeck khong active.
- Co danh sach macOS/version da test.
- Co quyet dinh ky thuat cu the cho global mode.
- Neu global mode khong kha thi tren may muc tieu, phai dung lai va doi strategy, khong tiep tuc lam UI nhu san pham da dat muc tieu.

### Phase 1.5: Global Runtime Hardening

Muc tieu:

- Tach `GlobalTouchBarPresenter` khoi renderer.
- Boc private/undocumented call bang runtime availability checks.
- Tu khoi phuc khi presenter bi mat sau app switch, sleep/wake, screen lock/unlock hoac Touch Bar service reset.
- Them Start/Stop Runtime.
- Them Launch at Login.
- Them Compatibility panel trong Studio.
- Ghi log runtime va hien last error gon trong UI.

Ket qua:

- Runtime co the chay nen on dinh trong 1-2 gio test thu cong.
- Dong Studio window khong lam mat Touch Bar layout.
- Chuyen qua lai nhieu app khong lam mat layout.
- Console khong co canh bao AppKit Touch Bar `too large` hoac `not enough space` sau khi khoi dong global runtime.
- Neu global presenter loi, app fallback co thong bao ro.

### Phase 2: Core Data Model

Muc tieu:

- Dinh nghia layout/profile JSON.
- Tao ProfileStore.
- Tao FunctionRegistry.
- Tao WidgetRegistry.
- Tao ActionDispatcher.

Ket qua:

- Runtime va Studio dung chung mot model.
- Layout co the luu/load on dinh.

### Phase 3: Virtual Touch Bar Editor

Muc tieu:

- Xay dung TouchDeck Studio.
- Co Virtual Touch Bar.
- Keo tha item tu library vao canvas.
- Reorder va resize.
- Chon item de edit trong inspector.

Ket qua:

- Nguoi dung co the tao layout bang UI.
- Layout tren man hinh co the render ra Touch Bar that.

### Phase 4: App Button

Muc tieu:

- App picker.
- Scan installed apps.
- Lay app icon.
- Theo doi app running/active.
- Launch/activate app.
- Hien indicator.

Ket qua:

- Touch Bar co the dung nhu mini Dock.

### Phase 5: Function Buttons

Muc tieu:

- Implement cac function co ban.
- Inspector co UI chon function va parameter.
- Test action ngay trong Studio.

Ket qua:

- Nguoi dung co the tao nut workflow ca nhan.

### Phase 6: Widgets

Muc tieu:

- RAM widget.
- SSD widget.
- CPU/Battery neu kha thi.
- Widget refresh engine.
- Widget error/cache state.

Ket qua:

- Touch Bar co the hien thong so he thong on dinh.

### Phase 7: System Buttons

Muc tieu:

- Implement system actions theo nhom.
- Tao compatibility matrix.
- Xu ly permission/fallback.

Ket qua:

- TouchDeck co the thay the phan lon Touch Bar goc.

### Phase 8: Polish and Distribution

Muc tieu:

- Auto launch at login.
- Import/export profiles.
- Backup/restore config.
- Notarization.
- App icon.
- Onboarding.
- Permission Center day du.
- UI polish theo design direction.
- Beta distribution ngoai App Store.
- Release note ghi ro Global Touch Bar la compatibility-sensitive feature.

Ket qua:

- Ban beta co the gui cho nguoi dung test.

## 11. Suggested Tech Stack

De xuat:

- Swift.
- AppKit cho Touch Bar runtime.
- Runtime wrapper rieng cho Global Touch Bar presentation.
- SwiftUI cho Studio UI neu phu hop.
- Combine/Observation cho state.
- JSON/Codable cho profile.
- NSWorkspace cho app discovery va app state.
- SF Symbols cho system icons.
- os.log cho logging.

Can nghien cuu them:

- MTMR source va co che giu Touch Bar hien thi khi app khong active.
- Private/undocumented Touch Bar presentation API tren macOS muc tieu.
- Cach detect Touch Bar hardware that.
- Cach recover khi Touch Bar service/presenter bi reset.
- Cac key codes/system events cho system buttons.
- Cach lay thong so RAM/SSD/CPU on dinh tren macOS.
- Weather provider va chinh sach location/network.

Ghi chu distribution:

- Neu dung private/undocumented API cho Global Touch Bar, khong nen dat muc tieu App Store trong giai doan dau.
- Huong phu hop hon la direct distribution: signed + notarized app, beta build, release note ro rang.
- Can QA tren chinh MacBook Pro co Touch Bar, khong chi simulator/window screenshot.

## 12. Success Criteria

MVP thanh cong khi:

- Nguoi dung co the mo app, keo nut vao Touch Bar ao, luu layout.
- Touch Bar that render dung layout do khi TouchDeck active.
- Touch Bar that van giu layout do khi nguoi dung chuyen sang Finder/Xcode/Safari hoac app khac.
- TouchDeck Studio window co the dong nhung runtime van tiep tuc hien tren Touch Bar.
- App Button co icon dung va indicator dang chay.
- Tap App Button launch/activate app dung.
- Tap App Button khi dang o app khac van launch/activate app dung.
- Function Button copy/paste/open URL/shortcut hoat dong.
- Function Button copy/paste/shortcut hoat dong trong app khac neu du permission.
- RAM/SSD widget cap nhat on dinh.
- Runtime status noi ro dang Global Active hay Fallback/Error.
- UI trong sang, toi gian, premium, dung tinh than macOS.
- Khong crash khi thieu permission hoac action loi.

Tieu chi "chua dat":

- Touch Bar chi hien layout TouchDeck khi TouchDeck dang active.
- Chuyen sang app khac thi Touch Bar quay ve macOS/app default.
- Runtime mat Touch Bar sau sleep/wake ma khong recover.
- Global mode loi nhung UI khong bao ro ly do.
