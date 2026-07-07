# TouchDeck

TouchDeck là một ứng dụng macOS biến Touch Bar trên MacBook Pro thành một bảng điều khiển kiểu Stream Deck. Người dùng có thể tự sắp xếp các nút trên Touch Bar thật thông qua một Touch Bar ảo trong app, kéo thả nút, tạo nhiều layout, chuyển layout, mở app nhanh, chạy phím tắt, điều khiển hệ thống và xem thông số máy.

Ứng dụng đang được thiết kế theo hướng native macOS, tối giản và premium, lấy cảm hứng từ System Settings, Finder, Xcode, TestFlight, Raycast, Arc Browser, CleanShot X, Linear và Notion Calendar.

## Tính Năng Chính

- Touch Bar ảo để sắp xếp nút bằng kéo thả.
- Chạy global Touch Bar để layout của TouchDeck vẫn hiển thị khi chuyển sang app khác.
- Hỗ trợ tối đa 5 layout song song.
- Nút Switch Layout để chuyển qua lại giữa các layout.
- Quy tắc bắt buộc Switch Layout khi có nhiều layout để không bị kẹt ở một layout.
- App Button giống Dock: mở app, focus app đang chạy, unhide app đang bị ẩn.
- Danh sách app quét từ `/Applications`, `~/Applications`, `/System/Applications`, `/System/Applications/Utilities` và `/Applications/Utilities`.
- Function Button cho copy, paste, control paste, undo, redo, select all, mở URL, mở file/folder, chạy shell, AppleScript, shortcut macOS và điều khiển app hiện tại.
- System Button cho âm lượng, độ sáng, mute, media, Mission Control, Launchpad, screenshot, emoji picker, khóa màn hình và sleep.
- Slider âm lượng và độ sáng dạng 2 cells, chỉ có thanh trượt, thumb là icon loa hoặc mặt trời.
- Widget hiển thị phần trăm RAM, SSD, CPU, pin bằng số màu theo mức sử dụng.
- RAM widget có thể bấm để mở Activity Monitor.
- Profile mặc định và profile riêng theo app đang frontmost.
- Lưu, import/export profile JSON.
- Menu bar runtime để start/stop/re-present Touch Bar.
- Test suite cho core rules, profile store, app discovery, layout editing và studio store.

## Thiết Kế Nút

TouchDeck dùng quy tắc hiển thị gọn cho Touch Bar thật:

- Phần lớn nút mặc định là 1 cell và chỉ hiển thị icon.
- Slider là ngoại lệ, dùng 2 cells.
- App Button luôn 1 cell và chỉ hiển thị icon app.
- Widget phần trăm chỉ hiển thị số phần trăm, không hiển thị logo.
- Màu phần trăm chia theo bậc:
  - `0-20%`: xanh
  - `20-40%`: mint
  - `40-60%`: vàng
  - `60-80%`: cam
  - `80-100%`: đỏ

## Yêu Cầu Hệ Thống

- macOS 14 trở lên.
- MacBook Pro có Touch Bar để test đầy đủ runtime thật.
- Swift 6 / Xcode toolchain tương thích Swift Package Manager.

Một số hành động cần quyền hệ thống:

- Accessibility: keyboard shortcut, Mission Control, screenshot, emoji picker và một số system action.
- Automation: AppleScript, volume slider và các action điều khiển app khác.
- Location/Network: widget thời tiết nếu dùng.

## Build Và Chạy

Chạy test:

```bash
swift test
```

Build binary SwiftPM:

```bash
swift build -c release --product TouchDeck
```

Đóng gói thành `.app` local:

```bash
./scripts/package_app.sh
```

App bundle sẽ được tạo tại:

```text
dist/TouchDeck.app
```

Mở app:

```bash
open dist/TouchDeck.app
```

Verify chữ ký local:

```bash
codesign --verify --deep --strict --verbose=2 dist/TouchDeck.app
```

## Developer ID Signing

Mặc định script dùng ad-hoc signing cho development. Để ký bằng Developer ID:

```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/package_app.sh
```

Xem thêm checklist phát hành tại [docs/distribution.md](docs/distribution.md).

## Cấu Trúc Dự Án

```text
Sources/
  TouchDeckApp/       Entry point của app.
  TouchDeckCore/      Models, catalogs, profile store, validation, app discovery, stats.
  TouchDeckRuntime/   Global Touch Bar runtime, renderer, action dispatcher.
  TouchDeckStudio/    UI editor, layout store, drag/drop, inspector.

Tests/
  TouchDeckCoreTests/
  TouchDeckStudioTests/

Packaging/
  Info.plist
  TouchDeck.entitlements

docs/
  beta-qa.md
  distribution.md
```

## Kiến Trúc

TouchDeck được chia thành bốn module:

- `TouchDeckCore`: chứa dữ liệu và luật nền như `TouchBarProfile`, `TouchBarPage`, `TouchBarItemConfig`, catalog action/widget/function, app discovery, profile codec và validator.
- `TouchDeckRuntime`: render layout lên Touch Bar thật, dispatch action, cập nhật widget và giữ global runtime.
- `TouchDeckStudio`: giao diện editor native SwiftUI/AppKit, virtual Touch Bar, drag/drop layout và inspector.
- `TouchDeckApp`: bootstrap app, window, menu bar runtime và kết nối Studio với Runtime.

Profile được lưu dưới dạng JSON trong Application Support thông qua `ProfileStore`. Khi load/save/render, profile được normalize theo rule hiện tại để tránh layout cũ hiển thị sai kích cỡ.

## Global Touch Bar

TouchDeck hướng tới trải nghiệm Touch Bar hiện ở mọi app, tương tự nhóm app như MTMR. Cơ chế này phụ thuộc vào API/private behavior của macOS Touch Bar, vì vậy:

- Nên phát hành trực tiếp bằng Developer ID signing và notarization.
- Không nên kỳ vọng phù hợp App Store nếu còn phụ thuộc global/private Touch Bar presentation.
- macOS update có thể làm thay đổi hành vi runtime.
- App vẫn cần fallback rõ ràng khi global runtime không khả dụng.

## QA

Checklist beta chi tiết nằm tại [docs/beta-qa.md](docs/beta-qa.md).

Các điểm cần test trên máy có Touch Bar thật:

- Layout vẫn hiện khi chuyển sang Finder, Safari, Xcode hoặc app khác.
- App Button mở/focus/unhide app đúng.
- Copy/paste tác động vào app frontmost, không phải TouchDeck Studio.
- Slider âm lượng/độ sáng phản hồi mượt.
- RAM widget mở Activity Monitor khi bấm.
- Switch Layout hoạt động ở mọi layout.
- Profile app-specific tự đổi theo frontmost app.

## Trạng Thái

TouchDeck đang ở giai đoạn prototype/beta nội bộ. Các tính năng chính đã có nền tảng hoạt động, nhưng cần tiếp tục QA trên máy có Touch Bar thật, nhất là global runtime, quyền Accessibility/Automation và tương thích theo phiên bản macOS.

## License

TouchDeck được phát hành theo giấy phép GNU General Public License v3.0 hoặc phiên bản mới hơn. Xem chi tiết tại [LICENSE](LICENSE).
