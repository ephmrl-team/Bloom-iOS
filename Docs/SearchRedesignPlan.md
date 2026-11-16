# Bloom — редизайн поиска: план для новой сессии

Дата: 2026-11-16  
Baseline: `main` @ `00b51b2`  
Устройство: iPhone 13 Pro «iPhone Рома»  
Bundle ID: `pw.ephmrl.bloom`

Этот файл — самодостаточный план. Новую сессию можно начинать с него, не читая предыдущий чат.

---

## 0. Как начать новую сессию

1. Прочитать `AGENTS.md` целиком.
2. `git checkout main && git pull`.
3. Убедиться, что HEAD — `00b51b2` или новее; текущая реализация поиска в этом коммите.
4. Проверить устройство:
   ```bash
   xcrun devicectl list devices
   ```
   Ожидается `iPhone Рома`, devicectl UUID `5EF96DBD-8C8E-547D-B6EE-EF6F97974AFC`, xcodebuild destination id `00008110-001610AE1E38401E`.
5. Собрать, установить и запустить:
   ```bash
   xcodebuild -project Bloom.xcodeproj -scheme Bloom \
     -destination 'platform=iOS,id=00008110-001610AE1E38401E' \
     -configuration Debug -derivedDataPath build/DerivedData build

   xcrun devicectl device install app \
     --device 5EF96DBD-8C8E-547D-B6EE-EF6F97974AFC \
     build/DerivedData/Build/Products/Debug-iphoneos/Bloom.app

   xcrun devicectl device process launch \
     --device 5EF96DBD-8C8E-547D-B6EE-EF6F97974AFC \
     pw.ephmrl.bloom
   ```
6. Эталонное видео:  
   `/Users/askold/Downloads/ScreenRecording_11-16-2026 03-53-12_1.mp4`  
   848×253, 10.6 c, H.264. Это кроп навбара приложения GitHub.
7. Эталон поведения: **GitHub iOS app** — поиск нативно живёт в верхнем баре, но само поле кастомное; кнопка поиска, поле и правая кнопка (X) анимируются как одна система.

---

## 1. Цель и non-negotiables

### 1.1. Цель

Сделать поиск в чатах, который:

- нативно интегрирован в `NavigationStack` toolbar;
- использует кастомное поле поиска (свой glass-капсул, свои иконки, скруглённый шрифт);
- морфится из кнопки поиска в поле и обратно **1:1 как на видео**;
- превращает composer в X на время поиска;
- сохраняет нативные кнопки, press-анимации и анимации переходов между экранами;
- сохраняет заголовок по центру и его dissolve;
- сохраняет ProgressiveBlur.

### 1.2. Нельзя нарушать

1. **Тулбар остаётся нативным.** Никакого `ChatListHeader` вместо навбара. Поиск, заголовок, composer — нативные `ToolbarItem`.
2. **`topVariableBlur()` не удалять.** ProgressiveBlur — святое. Никакой глухой заливки, никакого `scrollEdgeEffectStyle` вместо него. Правило уже в `AGENTS.md` §2.10.
3. **Кнопка поиска — настоящая нативная кнопка** в `.topBarLeading`, с нативным press-эффектом и нативной анимацией перехода между экранами.
4. **Заголовок — нативный `.principal`**, центрируется системой.
5. **Composer — настоящая нативная кнопка** в `.topBarTrailing`, ровно `44×44`, иконка `28`, без вложенной второй кнопки.
6. **Composer превращается в X во время поиска.** X закрывает поиск и очищает текст.
7. **Поле кастомное:** glass-капсул, `magnifyingglass`, `x.mark` (X — это composer), `.system(.body, design: .rounded)`.
8. **Поле занимает всю ширину, кроме composer/X справа.**
9. **Заголовок растворяется** строго через `.smooth`: `opacity 1→0`, `scale 1→1.2`, `blur 0→6`.
10. **Кнопки не статичные:** нативные `.glass` / `.glassProminent`, нативные press-анимации, нативные переходы между экранами.
11. **Никаких двойных кнопок.** Стекло кнопки рисует нативный button style; снаружи кнопки стекла быть не должно.
12. **Физическое устройство**, без симулятора.
13. Тесты сейчас не нужны; проверка вручную + запись экрана и сравнение с эталоном.

---

## 2. Эталон: GitHub и видео

### 2.1. Что делает GitHub

Верхний бар GitHub:

- в свёрнутом состоянии — стеклянная кнопка поиска;
- тап — из неё растёт стеклянная капсула поля;
- поле занимает ширину бара, справа остаётся отдельная кнопка X;
- кнопка, из которой росло поле, и X — визуально одна и та же правая кнопка;
- поле кастомное: свой placeholder, свои иконки, свой шрифт;
- кнопки при этом нативные, с нативными press/navigation-анимациями.

Нам нужно повторить **поведение**, а не пиксели GitHub. Наш layout зеркальный: кнопка поиска слева, composer/X справа.

### 2.2. Что видно на видео

Текущий анализ по кадрам 0.25 c:

- `0.00–1.00 c` — свёрнуто: справа стеклянный круг с лупой.
- `1.00–1.50 c` — круг растягивается влево в стеклянную капсулу; это **одна непрерывная glass-форма**, не кроссфейд.
- `1.50 c` — поле на всю ширину; справа отдельный круг X; лупа слева внутри поля; placeholder и курсор.
- `~2.00 c` — поле сфокусировано.
- далее циклы открытия/закрытия; закрытие — обратное сжатие капсулы в круг, X → лупа.

Ключевые свойства эталона:

1. Поле — **одна glass-капсула**, которая непрерывно меняет ширину.
2. Контент поля (placeholder, курсор) появляется **во время** растяжения.
3. Лупа остаётся у ведущего края.
4. Правая кнопка непрерывно превращается из лупы в X (иконка/tint/действие).
5. Длительность раскрытия ~`0.4–0.5 c`, smooth/spring без заметного баунса.

### 2.3. Обязательный протокол 0.1 c

Эталон **обязательно** разбирать с шагом `0.1 c`, а не 0.25 c. Тест на телефоне записывать и разбирать с **тем же шагом 0.1 c**. Сравнение — покадровое, по таблице.

Скрипт извлечения кадров:

```swift
import AVFoundation
import AppKit

@main
struct ExtractFrames {
    static func main() async throws {
        let asset = AVURLAsset(url: URL(fileURLWithPath: CommandLine.arguments[1]))
        let duration = try await asset.load(.duration)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let out = URL(fileURLWithPath: CommandLine.arguments[2])
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

        var t = 0.0
        var i = 0
        while t <= CMTimeGetSeconds(duration) {
            let (cg, _) = try await generator.image(at: CMTime(seconds: t, preferredTimescale: 600))
            let rep = NSBitmapImageRep(cgImage: cg)
            let data = rep.representation(using: .png, properties: [:])!
            try data.write(to: out.appendingPathComponent(String(format: "frame_%03d.png", i)))
            t += 0.1
            i += 1
        }
        print("frames=\(i)")
    }
}
```

Сборка и запуск:

```bash
xcrun swiftc -parse-as-library -o extract_frames extract_frames.swift
./extract_frames "/Users/askold/Downloads/ScreenRecording_11-16-2026 03-53-12_1.mp4" ref_frames
```

Для теста:

1. Записать экран iPhone (QuickTime Player / встроенная запись) в 60 fps.
2. Перенести видео на Mac.
3. Извлечь кадры тем же скриптом с шагом `0.1 c` в `app_frames`.
4. Совместить старт анимации (первый кадр после тапа) в обоих наборах.
5. Заполнить таблицу:

| t, c | reference: ширина/состояние | app: ширина/состояние | delta | заметки |
|---|---|---|---|---|
| 0.0 | 44 / кнопка | | | тап |
| 0.1 | | | | |
| ... | | | | |
| 0.5 | full / поле | | | полное раскрытие |

Критерий 1:1:
- старт раскрытия совпадает по кадру;
- полное раскрытие — в пределах ±1 кадра 0.1 c;
- кривая ширины совпадает на промежуточных кадрах;
- placeholder/курсор появляются на том же этапе;
- X/tint меняются синхронно;
- закрытие — обратная кривая с теми же таймингами.

Подгонять `duration`/`bounce` до совпадения. Не считать «на глаз».

---

## 3. Прошлые ошибки и их причины

| Ошибка | Причина | Как не повторять |
|---|---|---|
| Убрал нативный тулбар | Сделал `ChatListHeader` вместо `.toolbar` | Только нативные `ToolbarItem` |
| Убрал ProgressiveBlur | Заменил кастомным хедером | `.topVariableBlur()` всегда |
| Плоское поле | `Capsule().fill(...)` | `.glassEffect(.regular, in: Capsule())` |
| Двойные кнопки | Кастомное стекло снаружи `Button` + `.interactive()` | Нативные `.glass`/`.glassProminent`; стекло только внутри кнопки |
| Composer не 44×44 | Нативный стиль без фиксированного фрейма | `.frame(width: 44, height: 44)` + замер |
| Поиск не кнопка | Кнопка внутри `.principal`-контента | Отдельный `.topBarLeading` `ToolbarItem` |
| Заголовок съезжал | Overlay внутри principal-контента | Нативный `.principal` |
| Нет анимаций между экранами | Поиск/composer — кастомный контент | Все три — нативные `ToolbarItem` |
| Нет морфинга | Toolbar item swap / `glassEffectID` кроссфейд | Одна glass-капсула, непрерывная ширина |
| `matchedGeometryEffect` не сработал | Toolbar items в разных host-вьюхах | Не использовать между toolbar items |
| Поле не фокусировалось | `TextField` в toolbar host | Поле в overlay в основной иерархии |
| Анимация дёргалась | Глобальный `.animation` + toolbar swap | Один `withAnimation`, без глобальных анимаций |
| Кнопки «не кнопки» | Кастомные вью вместо нативных button styles | `.glass`/`.glassProminent` |

---

## 4. Варианты решения

### Вариант A — основной: нативный toolbar + кастомное поле overlay над навбаром

- Поиск, заголовок, composer — нативные `ToolbarItem` (нативные кнопки/анимации).
- Поле — отдельный glass-слой над навигационным баром, через UIKit-хост (`UINavigationController.view`).
- Поле растёт из фрейма нативной кнопки поиска до фрейма перед composer.
- Composer — нативная кнопка, превращается в X.
- Заголовок — нативный `.principal`, растворяется.

Плюсы: все требования, непрерывный 1:1 морфинг, нативные кнопки и переходы, кастомное поле.  
Минусы: UIKit-хост, hit-testing, accessibility, координация фреймов.

**Это предпочтительный вариант: нативный toolbar + кастомное поле, которое взаимодействует с кнопками и анимируется.**

### Вариант B — нативный toolbar + поле в `.principal` с нативным toolbar-переходом

- Поиск `.topBarLeading`, заголовок `.principal`, composer `.topBarTrailing`.
- При поиске поле заменяет заголовок в `.principal`; composer → X.
- Кнопки нативные, переходы нативные, ProgressiveBlur на месте.
- Морфинг — нативный toolbar swap, **не 1:1** с видео; поле появляется/исчезает, а не растягивается непрерывно.

Плюсы: проще, без UIKit-хоста, нативные кнопки.  
Минусы: нет непрерывного glass-морфинга. Fallback, если overlay-хост не подходит.

### Вариант C — кастомный principal-контент (поиск + composer + заголовок в одном `.principal`)

- Один `.principal` item, внутри — поиск/поле, composer/X, заголовок overlay.
- Непрерывный width-морфинг, заголовок можно центрировать.
- Кнопки — кастомные вью, не нативные toolbar items: нет нативных navigation-анимаций; пользователь это уже отверг.

Плюсы: проще анимация.  
Минусы: кнопки не нативные, нет анимаций между экранами. **Не использовать.**

### Вариант D — нативный `.searchable`

- Системный поиск: нативная кнопка, нативное поле, нативный морфинг.
- Поле нельзя полностью кастомизировать (шрифт/иконки/placeholder — системные); composer не превращается в X.

Плюсы: максимально нативно, минимум кода.  
Минусы: не кастомное поле, нет composer→X. Fallback, если кастомность поля не критична.

### Вариант E — кастомный хедер

- Полный контроль над анимацией 1:1.
- Нет нативного тулбара и нативных переходов. Пользователь отверг.

**Не использовать.**

### Сравнение

| Вариант | Нативные кнопки/переходы | Кастомное поле | 1:1 морфинг | Сложность |
|---|---|---|---|---|
| A | да | да | да | высокая |
| B | да | да | нет | низкая |
| C | нет | да | да | средняя |
| D | да | нет | нативный | низкая |
| E | нет | да | да | средняя |

Основной — **A**.

---

## 5. Вариант A: детальная архитектура

### 5.1. Нативный toolbar

`ChatListView`:

```swift
content
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden(true)
    .toolbar {
        ChatListToolbar(searchText: $searchText, isSearching: $isSearching)
    }
    .topVariableBlur()
```

`ChatListToolbar`:

- `.topBarLeading` — нативная кнопка поиска:
  - `Button { expandSearch() } label: { Image("magnifyingglass").frame(width: 28, height: 28) }`
  - `.buttonStyle(.glass)`
  - `.buttonBorderShape(.circle)`
  - `.accessibilityIdentifier("searchButton")`
  - при поиске: `.opacity(isSearching ? 0 : 1)`, но остаётся в layout.
- `.principal` — `ChatListTitle`:
  ```swift
  .opacity(isSearching ? 0 : 1)
  .scaleEffect(isSearching ? 1.2 : 1)
  .blur(radius: isSearching ? 6 : 0)
  .animation(.smooth(duration: 0.3), value: isSearching)
  ```
- `.topBarTrailing` — composer:
  - одна нативная кнопка, `44×44`, иконка `28` (compose) / `24` (X);
  - `.buttonStyle(.glassProminent)` с tint `primary` → `secondary` (или `.glass` для X, если так ближе к видео);
  - при поиске меняются иконка, tint, action, accessibility id (`searchCloseButton` / `newMessageButton`).

Не оборачивать кнопки в `.glassEffect` снаружи. Если нативный стиль не даёт ровно 44×44 — замерить `onGeometryChange` и подогнать frame/controlSize; в крайнем случае один кастомный `ButtonStyle`, рисующий стекло внутри кнопки, без `.interactive()`, с проверкой отсутствия двойного фона.

### 5.2. Захват геометрии

На кнопке поиска и composer:

```swift
.onGeometryChange(for: CGRect.self) { proxy in
    proxy.frame(in: .global)
} action: { frame in
    geometry.searchButtonFrame = frame
}
```

Модель:

```swift
@Observable
final class ChatListSearchGeometry {
    var searchButtonFrame: CGRect = .zero
    var composerFrame: CGRect = .zero

    var collapsedFieldFrame: CGRect {
        CGRect(x: searchButtonFrame.minX, y: searchButtonFrame.minY,
               width: searchButtonFrame.width, height: 44)
    }

    var expandedFieldFrame: CGRect {
        CGRect(x: searchButtonFrame.minX, y: searchButtonFrame.minY,
               width: max(44, composerFrame.minX - Theme.spacing.md - searchButtonFrame.minX),
               height: 44)
    }
}
```

Глобальные координаты конвертировать в координаты overlay-хоста через `convert(_:from: nil)`.

### 5.3. Overlay-хост над навбаром

Обычный SwiftUI `.overlay` на `ChatListView` будет **под** навигационным баром. Нужен UIKit-хост:

- `UIViewControllerRepresentable` / `UIViewRepresentable`, который находит `UINavigationController`;
- добавляет прозрачный `UIHostingController` в `navigationController.view` после навбара;
- убирает хост при исчезновении экрана;
- хост полноэкранный и прозрачный; hit-testing только в области поля (override `point(inside:)` или `PassthroughHostingView`).

Поле — в основной иерархии, поэтому `@FocusState` и клавиатура работают нормально.

### 5.4. Состояние

```swift
@State private var isSearching = false      // overlay видим, нативная кнопка/заголовок скрыты, composer = X
@State private var isFieldExpanded = false  // ширина поля: 44 или полная
```

Открытие:

```swift
isSearching = true
withAnimation(.smooth(duration: 0.4)) {
    isFieldExpanded = true
}
```

Закрытие:

```swift
withAnimation(.smooth(duration: 0.4)) {
    isFieldExpanded = false
} completion: {
    isSearching = false
    searchText = ""
}
```

Поле всегда в иерархии; при `isSearching == false` оно прозрачно и не перехватывает тапы. При открытии появляется ровно во фрейме нативной кнопки, затем растягивается. При закрытии сжимается обратно и только потом исчезает.

### 5.5. Поле

`ChatSearchField` — только поле, без кнопки и без close:

```swift
HStack(spacing: Theme.spacing.sm) {
    Image("magnifyingglass")
        .frame(width: 18, height: 18)

    TextField("Search", text: $text)
        .font(.system(.body, design: .rounded))
        .focused($isFocused)
        .submitLabel(.search)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .opacity(isExpanded ? 1 : 0)
        .allowsHitTesting(isExpanded)
}
.padding(.horizontal, Theme.spacing.md)
.frame(width: fieldFrame.width, height: 44, alignment: .leading)
.glassEffect(.regular, in: Capsule())
.position(x: fieldFrame.midX, y: fieldFrame.midY)
```

- одна glass-капсула на всё время анимации;
- лупа всегда слева;
- `TextField` всегда в иерархии, но прозрачный/неинтерактивный в свёрнутом состоянии;
- фокус — после завершения раскрытия (completion), затем клавиатура;
- X внутри поля нет — X это composer.

### 5.6. Composer → X

Одна нативная кнопка в `.topBarTrailing`:

- collapsed: `square.and.pencil` 28, `.glassProminent`, tint `primary`, action `router.presentModal(.newMessage)`;
- searching: `x.mark` 24, tint `secondary` (или regular glass), action `closeSearch()`;
- размер 44×44 в обоих состояниях;
- иконка — `.transition(.opacity)`, tint — `.animation(.smooth(duration: 0.2))`;
- accessibility label/id меняются.

Никакого стекла снаружи кнопки. Если `.glassProminent` с серым tint слишком светлый — две условные кнопки в одном toolbar item: `.glassProminent` для compose, `.glass` для X; проверить, что фон не двойной.

### 5.7. Заголовок

Нативный `.principal`, модификаторы dissolve — на `ChatListTitle`. Если навбар клипует scale/blur, обернуть с запасом по frame или (fallback) рисовать копию заголовка в overlay и скрывать нативный.

### 5.8. ProgressiveBlur

`.topVariableBlur()` на `ChatListView` остаётся. Overlay-поле выше бара, blur — под ним. Никакой глухой заливки/`scrollEdgeEffectStyle`.

### 5.9. Анимация

Раскрытие:
- `isSearching = true` — overlay в `collapsedFieldFrame`, нативная кнопка гаснет, заголовок начинает dissolve, composer → X;
- сразу `withAnimation(.smooth(duration: 0.4)) { isFieldExpanded = true }`;
- ширина `44 → expandedFieldFrame.width`, x фиксирован на `searchButtonFrame.minX`;
- glass-капсула растягивается; лупа остаётся; `TextField` opacity `0→1`;
- фокус после completion.

Закрытие:
- `withAnimation(.smooth(duration: 0.4)) { isFieldExpanded = false }`;
- ширина `expanded → 44`, `TextField` opacity `1→0`;
- заголовок reverse dissolve;
- composer X → compose;
- completion: `isSearching = false`, `searchText = ""`.

Стартовые тайминги:
- раскрытие/закрытие: `.smooth(duration: 0.4)` или `Spring(duration: 0.45, bounce: 0.05)`;
- заголовок: `.smooth(duration: 0.3)`;
- composer icon/tint: `.smooth(duration: 0.2)`.

Далее — подгонка по протоколу 0.1 c.

---

## 6. Файлы

Новые:
- `Bloom/Features/ChatList/ChatListSearchGeometry.swift`
- `Bloom/Features/ChatList/ChatSearchOverlay.swift`
- `Bloom/Features/ChatList/NavigationBarOverlayHost.swift`

Изменяемые:
- `Bloom/Features/ChatList/ChatListView.swift` — состояния, `.toolbar`, `.topVariableBlur()`, overlay host, `onDisappear`.
- `Bloom/Features/ChatList/ChatListToolbar.swift` — нативные items, захват фреймов, dissolve, composer → X.
- `Bloom/Features/ChatList/ChatSearchField.swift` — только поле, glass-капсула, без кнопки/close.

Не трогать:
- `ChatListModifiers.swift` — ProgressiveBlur.
- `AGENTS.md` — правило §2.10 уже есть.
- Фильтрацию чатов, empty state, роутинг.

---

## 7. Порядок реализации

1. Вернуть/закрепить нативные `.topBarLeading` поиск, `.principal` заголовок, `.topBarTrailing` composer.
2. Composer 44×44, icon 28, X-состояние.
3. Dissolve заголовка.
4. `ChatListSearchGeometry` + `onGeometryChange`.
5. UIKit-хост над навбаром + passthrough hit-testing.
6. Overlay-поле: одна glass-капсула, лупа, TextField, позиционирование.
7. State machine `isSearching` + `isFieldExpanded`, открытие/закрытие.
8. Фокус после раскрытия.
9. Сборка, установка, запись экрана, сравнение 0.1 c, подгонка.
10. Проверка навигации, табов, поворота, Reduce Motion/Transparency, VoiceOver, тем.
11. Коммит и пуш.

---

## 8. Проверка

Обязательно:
- нативные press-анимации кнопок;
- нативные переходы Chats → Settings → Chats;
- поиск — нативная кнопка; заголовок по центру;
- composer 44×44, одна кнопка, без вложенности;
- composer → X и обратно;
- поле glass, кастомный шрифт/иконки, full width кроме composer;
- 1:1 по протоколу 0.1 c;
- заголовок dissolve;
- ProgressiveBlur;
- фокус/клавиатура;
- фильтрация и очистка;
- таб-переключение при открытом поиске;
- поворот/iPad;
- Reduce Motion/Transparency;
- VoiceOver;
- тёмная/светлая тема;
- сборка/установка на iPhone.

Без UI-тестов, если не попросят отдельно.

---

## 9. Риски и fallback

1. **UIKit-хост над навбаром** — единственный способ совместить нативные кнопки/переходы и непрерывный морфинг. Если он неприемлем — вариант B (нативный swap, без 1:1) или D (`.searchable`).
2. **Стекло поля и фон навбара** могут выглядеть как двойное стекло. Проверить; при необходимости уменьшить tint/прозрачность, не добавляя вторую кнопку.
3. **Фреймы toolbar items** могут быть недоступны до layout — ждать `onGeometryChange`, обновлять при повороте.
4. **Заголовок scale/blur** может клипаться навбаром — обернуть/продублировать в overlay.
5. **Composer 44×44** нативным стилем — замерить; fallback один кастомный ButtonStyle с стеклом внутри.
6. **Hit-testing/accessibility overlay** — passthrough вне поля, скрыть нативные скрытые элементы из accessibility.
7. **Тайминг** — только покадровое сравнение 0.1 c, не «на глаз».

---

## 10. Критерии готовности

- [ ] Нативный toolbar, ProgressiveBlur, нативные кнопки/переходы.
- [ ] Поиск — нативная кнопка, заголовок — нативный `.principal`.
- [ ] Composer 44×44, icon 28, одна кнопка, composer → X.
- [ ] Кастомное glass-поле, full width кроме composer.
- [ ] Непрерывный морфинг 1:1 по 0.1 c.
- [ ] Заголовок dissolve `.smooth` (opacity/scale/blur).
- [ ] Фокус/клавиатура, фильтрация, очистка.
- [ ] Навигация/табы/поворот/Reduce Motion/Transparency/VoiceOver/темы.
- [ ] Собрано и установлено на iPhone.

---

## 11. Открытое решение

Основной вариант — **A** (нативный toolbar + кастомное поле overlay над навбаром). Он единственный одновременно даёт нативные кнопки/переходы и 1:1 glass-морфинг.

Если UIKit-хост над навбаром не подходит — выбрать **B** (нативный toolbar swap, без 1:1) или **D** (`.searchable`, без кастомного поля). Варианты C и E не использовать: они уже отвергнуты.
