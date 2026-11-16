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
6. Эталонные видео:
   - `/Users/askold/Downloads/ScreenRecording_11-16-2026 03-53-12_1.mp4` — старый кроп навбара, 848×253, 10.6 c;
   - `/Users/askold/Downloads/IMG_9936.MP4` — новый полный эталон, 1170×434, 17.6 c, GitHub iOS, тёмная тема; разбор в §2.4.
7. Эталон поведения: **GitHub iOS app** — поиск нативно живёт в верхнем баре, но само поле кастомное; кнопка поиска, поле, composer/X и back-кнопка анимируются как одна система.

---

## 1. Цель и non-negotiables

### 1.1. Цель

Сделать поиск в чатах, который:

- нативно интегрирован в `NavigationStack` toolbar;
- использует кастомное поле поиска (свой glass-капсул, свои иконки, скруглённый шрифт);
- морфится из кнопки поиска в поле и обратно **1:1 как на видео**;
- при переходе на новый экран морфится в нативную back-кнопку с `chevron.left` (поле — в leading-слоте), с нативной анимацией Apple;
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
14. **Navigation morph:** при push поле поиска морфится в нативную back-кнопку с `chevron.left`; поле концептуально занимает `.leading`-слот (там же, где back-кнопка). Кривые и bounce — нативные Apple; не оборачивать navigation push в кастомный `withAnimation`/`.smooth`. `.smooth` остаётся только для dissolve заголовка.

---

## 2. Эталон: GitHub и видео

### 2.1. Что делает GitHub

Верхний бар GitHub:

- в свёрнутом состоянии — стеклянная кнопка поиска;
- тап — из неё растёт стеклянная капсула поля;
- поле занимает ширину бара, справа остаётся отдельная кнопка X;
- кнопка, из которой росло поле, и X — визуально одна и та же правая кнопка;
- поле концептуально в leading-слоте: при push оно морфится в нативную back-кнопку с `chevron.left`;
- анимации (bounce/кривые) — нативные Apple, не кастомные;
- поле кастомное: свой placeholder, свои иконки, свой шрифт;
- кнопки при этом нативные, с нативными press/navigation-анимациями.

Нам нужно повторить **поведение**, а не пиксели GitHub. Наш layout зеркальный: кнопка поиска слева, composer/X справа. Новый полный эталон `IMG_9936.MP4` (тёмная тема) разобран в §2.4 и уточняет тайминги и navigation morph.

### 2.2. Что видно на видео

Старый кроп ниже (0.25 c). Новый полный эталон `IMG_9936.MP4` разобран в §2.4 с шагом 0.1 c; он уточняет тайминги и navigation morph.

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
5. Длительность раскрытия ~`0.4–0.5 c`; в новом эталоне ~`0.3–0.4 c`, bounce/кривые — нативные Apple.

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
./extract_frames "/Users/askold/Downloads/IMG_9936.MP4" ref_frames_9936
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

### 2.4. Новый эталон IMG_9936.MP4 (0.1 c)

Файл: `/Users/askold/Downloads/IMG_9936.MP4` — 1170×434, 17.6 c, HEVC, GitHub iOS, тёмная тема. Кадры извлечены с шагом 0.1 c (177 кадров).

#### Свёрнуто (0.0 c)
- Чёрный верхний бар; слева аватар, крупный `My Work`; справа одна общая тёмная glass-пилюля с `+` и лупой (~100×33 pt, тонкая светлая окантовка).
- `+` и лупа — две зоны одной glass-группы, не два отдельных круга.

#### Раскрытие (1.3–1.7 c)
- 1.3 c — лупа притушена (press).
- 1.4 c — pressed, `+` ещё виден, заголовок `My Work` виден.
- 1.5 c — иконки исчезли; на месте пилюли размытая glass-капсула; заголовок ещё виден.
- 1.6 c — широкая размытая капсула тянется влево до середины; правый край на месте; заголовок/аватар/`+` гаснут; текста ещё нет.
- 1.7 c — поле полностью раскрыто, стекло резкое.
- Длительность ~0.3–0.4 c; без заметного баунса; промежуточное размытие — motion blur. Кривые — нативные Apple.

#### Раскрытое состояние
- Поле ~273×33 pt, от ~39 до ~312 pt; отдельная glass-кнопка `X` ~33 pt на ~341–374 pt; зазор ~29 pt; правый отступ ~16 pt.
- В поле: лупа, серый `Search GitHub`, синий курсор; текст белый; при вводе — маленькая серая круглая кнопка очистки внутри поля у правого края; внешняя `X` остаётся отдельной и закрывает поиск.
- `X` — тёмное стекло, не синяя кнопка.
- Поле сразу в фокусе; клавиатура в кроп не видна.

#### Закрытие по X (12.3–12.6 c)
- 12.3 c — `X` нажат (ярче/крупнее).
- 12.4 c — поле схлопнулось вправо, `X` ещё остаётся.
- 12.5 c — размытая пилюля с `+`/лупой, вернулись аватар и `My Work`.
- 12.6 c — пилюля устоялась. ~0.3 c, обратный морф.

#### Ввод и переход на новый экран
- Ввод фильтрует контент (`Code with "n"`).
- Тап по результату → нативный push на `Code`: появляется навбар с back-кнопкой `‹` и заголовком `Code`.
- **Ключевое:** поле поиска в leading-слоте морфится в нативную back-кнопку с `chevron.left` (glass-круг); заголовок нового экрана появляется нативно. Это нативный navigation transition Apple; bounce/кривые — системные, не кастомный `.smooth`/`withAnimation`.
- Поле уходит вместе с экраном; отдельной кастомной анимации закрытия при push нет.

#### Адаптация для Bloom
- Layout зеркальный: поиск слева (leading), composer справа (trailing). Поле растёт вправо от поиска до composer; composer становится X; поле и X — отдельные glass-элементы с зазором.
- Поле 44 pt, composer 44×44/icon 28; кастомные иконки, скруглённый шрифт.
- Заголовок по центру, dissolve `.smooth` (opacity 1→0, scale 1→1.2, blur 0→6) — единственная явная кастомная кривая.
- При push поле морфится в нативную back-кнопку; ProgressiveBlur и нативный toolbar остаются.
- В видео X — тёмное стекло, а composer Bloom синий prominent; для 1:1 X делать обычным стеклом (или спросить, если хочется сохранить синий акцент).

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
| Поле не морфилось в back-кнопку при push | Overlay не участвовал в нативном navigation transition | Поле в leading-слоте + нативный push; overlay синхронизировать с back-кнопкой |

---

## 4. Варианты решения

### Вариант A — основной: нативный toolbar + кастомное поле overlay над навбаром

- Поиск, заголовок, composer — нативные `ToolbarItem` (нативные кнопки/анимации).
- Поле — отдельный glass-слой над навигационным баром, через UIKit-хост (`UINavigationController.view`).
- Поле растёт из фрейма нативной кнопки поиска до фрейма перед composer.
- Поле привязано к leading-слоту; при push морфится в нативную back-кнопку с `chevron.left` (glass-круг), заголовок нового экрана появляется нативно.
- Composer — нативная кнопка, превращается в X.
- Заголовок — нативный `.principal`, растворяется.
- Кривые/bounce — нативные Apple; кастомный `.smooth` только для dissolve заголовка.

Плюсы: все требования, непрерывный 1:1 морфинг, нативные кнопки/переходы/navigation morph, кастомное поле.

Минусы: UIKit-хост, hit-testing, accessibility, координация фреймов; overlay должен участвовать в нативном transition.

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
withAnimation(.snappy) {
    isFieldExpanded = true
}
```

Закрытие:

```swift
withAnimation(.snappy) {
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

Кривые:
- раскрытие/закрытие поля и navigation morph — **нативная анимация Apple** (системный toolbar/navigation transition), не кастомный `.smooth`;
- для ширины overlay использовать системный preset (`.snappy`/`.spring`), подогнанный по 0.1 c; не хардкодить `.smooth` для поля;
- `.smooth(duration: 0.3)` — только dissolve заголовка;
- navigation push не оборачивать в `withAnimation`: нативный push сам анимирует leading-слот.

Раскрытие:
- `isSearching = true` — overlay в `collapsedFieldFrame`, нативная кнопка гаснет, заголовок начинает dissolve, composer → X;
- `withAnimation(.snappy)` (или системный preset): `isFieldExpanded = true`;
- ширина `44 → expandedFieldFrame.width`, x фиксирован на `searchButtonFrame.minX`;
- glass-капсула растягивается; лупа остаётся; `TextField` opacity `0→1`;
- фокус после completion.

Закрытие:
- `withAnimation(.snappy)`: `isFieldExpanded = false`;
- ширина `expanded → 44`, `TextField` opacity `1→0`;
- заголовок reverse dissolve;
- composer X → compose;
- completion: `isSearching = false`, `searchText = ""`.

Стартовые тайминги:
- раскрытие/закрытие: системный `.snappy`/spring; подгонка по 0.1 c (в эталоне ~0.3–0.4 c);
- заголовок: `.smooth(duration: 0.3)`;
- composer icon/tint: `.smooth(duration: 0.2)`.

Далее — подгонка по протоколу 0.1 c. Если системный preset не совпадает с эталоном, снять кривую с нативного toolbar transition и повторить; не заменять navigation transition кастомным `withAnimation`.

### 5.10. Navigation morph: поле → back chevron

- Поле концептуально занимает leading-слот — тот же, где нативная back-кнопка.
- При push на новый экран (чат/результат) leading-слот меняется с поля на нативную back-кнопку; стекло поля морфится в glass-круг back-кнопки, появляется `chevron.left`; заголовок нового экрана появляется нативно.
- Это **нативный navigation transition** Apple: не оборачивать push в `withAnimation`, не делать кастомный `.smooth`/`.snappy` для этого перехода. Кривые/bounce — системные.
- Чтобы система могла морфить, поле должно быть либо нативным leading toolbar item, либо overlay, синхронизированный с фреймом/стеклом нативной back-кнопки на push. Если overlay не участвует в нативном переходе, он должен скрываться/передавать стекло back-кнопке в тот же кадр; проверить 0.1 c.
- Back-кнопка в видео — тёмный glass-круг с `chevron.left`, не плоский chevron. В Bloom использовать нативную back-кнопку с glass-стилем (если система позволяет) или overlay-копию, совпадающую по фрейму.
- Заголовок нового экрана — нативный; не рисовать кастомный.

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
- Navigation morph не требует нового файла: overlay синхронизируется с нативной back-кнопкой; при необходимости — `ChatListBackButtonMorph` в `ChatSearchOverlay.swift`.

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
9. Navigation morph: поле → нативная back-кнопка при push; проверить нативный transition и 0.1 c.
10. Сборка, установка, запись экрана, сравнение 0.1 c, подгонка.
11. Проверка навигации, табов, поворота, Reduce Motion/Transparency, VoiceOver, тем.
12. Коммит и пуш.

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
- navigation morph: поле → back chevron при открытии чата/результата;
- bounce/кривые — нативные Apple; navigation push не обёрнут в кастомный `withAnimation`;
- новый экран: нативный заголовок и back-кнопка (glass-круг);
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
8. **Navigation morph** — overlay может не участвовать в нативном push; если поле не в leading-слоте, back-кнопка не морфится. Решение: поле в leading-слоте/синхронизация с back-кнопкой; если невозможно — спросить.

---

## 10. Критерии готовности

- [ ] Нативный toolbar, ProgressiveBlur, нативные кнопки/переходы.
- [ ] Поиск — нативная кнопка, заголовок — нативный `.principal`.
- [ ] Composer 44×44, icon 28, одна кнопка, composer → X.
- [ ] Кастомное glass-поле, full width кроме composer.
- [ ] Непрерывный морфинг 1:1 по 0.1 c.
- [ ] Navigation morph: поле → back chevron с нативной анимацией Apple.
- [ ] Кривые/bounce поля и navigation — нативные; `.smooth` только заголовок.
- [ ] Заголовок dissolve `.smooth` (opacity/scale/blur).
- [ ] Фокус/клавиатура, фильтрация, очистка.
- [ ] Навигация/табы/поворот/Reduce Motion/Transparency/VoiceOver/темы.
- [ ] Собрано и установлено на iPhone.

---

## 11. Открытое решение

Основной вариант — **A** (нативный toolbar + кастомное поле overlay над навбаром). Он единственный одновременно даёт нативные кнопки/переходы, navigation morph (поле → back chevron) и 1:1 glass-морфинг.

Если UIKit-хост над навбаром не подходит — выбрать **B** (нативный toolbar swap, без 1:1) или **D** (`.searchable`, без кастомного поля). Варианты C и E не использовать: они уже отвергнуты.

Если leading-слот/overlay не позволяет нативный navigation morph — остановиться и спросить, не заменять его кастомной анимацией.
