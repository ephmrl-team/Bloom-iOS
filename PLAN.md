# План стабилизации Bloom iOS

Документ описывает поэтапный план исправления проблем, найденных при аудите
(`main`, коммит `3107366`). Этапы упорядочены по риску: сначала то, что теряет
данные и секреты, затем падения, затем архитектура режимов и производительность,
в конце — UI, тесты и процесс.

## 0. Ограничения и правила работы

- Сборка и проверка выполняются только на macOS с Xcode 26+, запуск и тесты —
  только на подключённом физическом устройстве. Симулятор не используется.
- `BloomKit.xcframework` в репозитории нет. Любой этап, который меняет контракт с
  ним, начинается с уточнения API у владельца фреймворка.
- Один этап — один логический коммит (или небольшая серия). После каждого этапа:
  Debug + Release сборка без новых предупреждений, `SWIFT_STRICT_CONCURRENCY=complete`
  без новых диагностик в затронутом коде.
- Если этап нельзя проверить на устройстве, это явно указывается в описании
  коммита и в отчёте.

## 1. Целевая архитектура режимов: DEV / MOCK / RELEASE

### 1.1 Требования

| Требование | DEV | MOCK | RELEASE |
|---|---|---|---|
| `ClientNewClient` создаётся | да | **нет, никогда** | да |
| Сетевые вызовы | да | **нет** | да |
| Запись в Keychain | да (реальный сервис) | нет (in-memory) | да |
| Реальная запись аудио | да | нет (заглушка-таймер) | да |
| Данные | реальные | seeded in-memory | реальные |
| Логи | verbose | verbose | только ошибки |
| Код моков в бинарнике | есть | есть | **отсутствует** |

Ключевое правило: **в MOCK-режиме API не работает вообще** — не «падает в
рантайме», а физически не может быть создан. Обращение к API в MOCK — ошибка
программиста, которая ловится `precondition`/`assertionFailure` в Debug.

### 1.2 Определение режима

Новый файл `Bloom/App/AppMode.swift`:

```swift
enum AppMode: String {
    case dev
    case mock
    case release

    static let current: AppMode = resolve()

    private static func resolve() -> AppMode {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.arguments
            .first(where: { $0.hasPrefix("-AppMode=") })?
            .split(separator: "=").last,
           let mode = AppMode(rawValue: String(raw)) {
            return mode
        }
        return .dev
        #else
        return .release
        #endif
    }

    var allowsRealAPI: Bool { self != .mock }
}
```

Источники значения, по приоритету:

1. launch argument `-AppMode=mock` — для схемы и UI-тестов;
2. `#if DEBUG` → `.dev`;
3. иначе `.release`.

`case mock` компилируется только в DEBUG: в Release запуск с аргументом `mock`
невозможен, моковый код вырезан препроцессором.

### 1.3 Точка сборки зависимостей

Заменить прямые обращения к `BloomKit` на протоколы (файлы в `Bloom/State/API/`):

```swift
protocol MessagingAPI: Sendable {
    func fetchChats() async throws -> [Chat]
    func send(text: String, to chatID: String) async throws -> ChatMessage
    func observeChats() -> AsyncStream<[Chat]>
}

protocol IdentityAPI: Sendable {
    func register() async throws -> (user: User, recoveryHex: String)
    func login(recoveryHex: String) async throws -> User
    func restoreSession() async throws -> User?
    func signOut() async
}
```

- `BloomKitAPI` — единственное место, где упоминается `ClientNewClient`.
  Инициализатор: `precondition(AppMode.current.allowsRealAPI)`.
- `MockAPI` (только `#if DEBUG`) — реализация на in-memory seeded данных:
  детерминированные чаты, пользователи, задержка 150 мс, история сообщений
  сохраняется в памяти.
- `AppEnvironment` (`Bloom/App/AppEnvironment.swift`) — composition root:
  создаёт `MessagingAPI`/`IdentityAPI`/репозитории по `AppMode.current` и
  инжектится через `.environment(...)`, как сейчас `BloomManager`.

### 1.4 Моковые данные

`Bloom/State/Mocks/` (под `#if DEBUG`): `MockChats.json`-подобные структуры в коде,
набор из 6 диалогов (личный, групповой, длинные имена, эмодзи, вложения),
история 40 сообщений на чат, состояния: пустой список, загрузка, ошибка (переключение
launch-аргументом `-MockScenario=empty|error|large`).

### 1.5 Критерии готовности этапа

- `grep -r "ClientNewClient" Bloom` даёт ровно один файл — `BloomKitAPI.swift`.
- В MOCK приложение стартует без Keychain (проверка: тестовый сервис пуст),
  без сети (URLSession не вызывается), отправка сообщения работает in-memory.
- Release-сборка не содержит `MockAPI` и `MockScenario` (проверка: символы в бинаре).
- UI-тесты запускают приложение с `-AppMode=mock` и не трогают реальный бэкенд.

---

## 2. Этап 1 — Секреты и восстановление аккаунта (критично)

Файлы: `Features/Auth/AuthWelcome/AuthWelcomeFooterView.swift`,
`Features/Auth/AuthWelcome/AuthWelcomeView.swift`, `Features/Auth/AuthSuccess/AuthSuccessView.swift`,
`Helpers/KeychainHelper.swift`, `State/BloomManager.swift`, `App/BloomApp.swift`.

1. Удалить `print(mnemonic)` (строка 34) и все печати секретов; перейти на
   `os.Logger` с `privacy: .private` для неконфиденциальных полей и без
   интерполяции секретов.
2. Спроектировать экран показа фразы (или явный шаг «сохраните фразу»):
   - 12 слов, нумерация, кнопка «Показать/Скрыть», запрет скриншотов
     (`UITextField` + `isSecureTextEntry` или отключение screen capture — проверить
     на устройстве), подтверждение 3 случайных слов перед переходом дальше;
   - очистка `@State` при `onDisappear` и при `scenePhase != .active`;
   - фон/оверлей в переключателе приложений.
3. `KeychainHelper`: `kSecAttrAccessible = kSecAttrAccessibleWhenUnlockedThisDeviceOnly`,
   атомарный upsert (`SecItemUpdate` → `SecItemAdd`), `throws` вместо `print`,
   `final class`, поддержка отдельного service для тестов.
4. `getOrCreateDatabaseKey`: проверять `SecRandomCopyBytes == errSecSuccess`,
   бросать ошибку при неудачной записи, не генерировать новый ключ молча;
   выровнять имя сервиса с bundle id (с миграцией существующих записей).
5. `logout()`: удалить recovery key и ключ БД (или хотя бы креды + данные),
   очистить чаты/сообщения/кэш пользователя, сбросить роутер на `AuthWelcome`;
   `checkSession()` не должен восстанавливать сессию после выхода.
6. Биометрия (`LocalAuthentication`) — отдельным этапом после стабилизации
   Keychain; до этого README не должен утверждать, что FaceID есть.
7. Тесты: доступность Keychain, round-trip/overwrite/delete, отсутствие секретов
   в логах, очистка фразы при уходе с экрана.

## 3. Этап 2 — Устранение падений

Файлы: `State/BloomManager.swift`, `Features/Chat/ChatView.swift`,
`Features/ChatList/ChatListToolbar.swift`, `Features/NewMessage/NewMessageView.swift`,
`Helpers/AvatarGradient.swift`.

1. Заменить `fatalError` в `init` на `throws`-инициализацию/состояние ошибки и
   экран «Не удалось запустить» с retry. Убрать `paths[0]` без проверки.
2. `ChatView`: `store.data.first?.me` вместо `first!`; добавить тест на пустой стор.
3. Убрать `namespace!`: либо гарантировать неопциональный namespace через
   обязательное значение в окружении, либо `if let`.
4. `avatarGradient`: хеш в `UInt` (`hashValue` → `% palette.count` без `abs`),
   убрать лишний `import CryptoKit`.

## 4. Этап 3 — Конкурентность и главный поток

Файлы: `State/BloomManager.swift`, `State/AudioRecorderManager.swift`,
`State/MessagesStore.swift`.

1. `init` не должен делать сетевые/дисковые вызовы: `initialize`/`restoreSession`
   переносятся в `Task` на старте `RootView` с экраном загрузки.
2. Синхронные методы клиента (`getMe`, `getUser`, `editUser`, `searchUsers`)
   переводятся в `async` и уходят с main actor; результаты возвращаются
   value-типами.
3. `Task.detached` с захватом не-`Sendable` клиента убрать: API-слой `Sendable`,
   вызовы через `async` без detached.
4. Пустой `catch {}` в `UserObserver` заменить на логирование и состояние ошибки.
5. NSObject-листенеры заменить на `AsyncStream` (через API-протокол), чтобы
   порядок событий был определён; один подписчик вместо слота `onUpdate`.
6. `AudioRecorderManager`: `@Observable` вместо `ObservableObject`, актёр/фоновый
   исполнитель для обработки сэмплов, публикация уровней не чаще 30 Гц в
   отдельной модели, которую читает только вьюха волны; `AVAudioSession`
   деактивируется в `deinit`/`stop`, временный файл удаляется, имя уникальное,
   `FileProtectionType.complete`.

## 5. Этап 4 — Производительность

Файлы: `State/Models/BloomManagerModels.swift`, `Features/ChatList/ChatListRow/ChatListRowView.swift`,
`Features/ChatList/ChatListView.swift`, `Features/Chat/ChatRowView.swift`,
`Features/Chat/ChatFooter/ChatFooterWaveformView.swift`, `Features/Chat/ChatView.swift`.

1. `ChatResponse.me/.recipient`: декодировать пользователя один раз при разборе
   чатов и хранить готовую display-модель (`ChatRowViewModel`: имя, аватар, время,
   превью последнего сообщения). `ChatsListRowView` не должен ничего декодировать.
2. `JSONDecoder` — `static let` (или актёр), а не computed; дату парсить
   `Date.ISO8601FormatStyle` вместо двух `ISO8601DateFormatter`.
3. `formatTime` — `Date.FormatStyle` или предвычисленная строка в модели; учитывать
   «сегодня/вчера/дата», не только `HH:mm`.
4. `ChatListView`: убрать `scrollY` на каждый пиксель; логотип вынести в маленькую
   вьюху с собственным `@Observable`-состоянием скролла или использовать
   `scrollTransition`/`visualEffect`.
5. `ChatRowView`: одна сборка пузыря, `Equatable` включает все входные данные
   (включая `date`, флаги группировки), убрать `.id(item.id)`; пересмотреть
   `UIKitContextMenu`, чтобы превью не создавалось для каждой строки заранее.
6. `ChatFooterWaveformView`: предвычислить высоты баров, рисовать один раз через
   `Canvas`, без per-bar `@State`/`onAppear`; проверить `drawingGroup()`.
   Замерить Instruments до/после.
7. Скролл чата: инверсию через `.scaleEffect(y: -1)` заменить на штатный
   `defaultScrollAnchor(.bottom)` + `scrollPosition`, если это не ломает
   поведение; при замене — обязательные замеры hitches до/после.
8. Зафиксировать базовые метрики (launch, скролл списка, скролл чата) в
   `BloomPerformanceTests/Baselines/`.

## 6. Этап 5 — Реальные данные вместо заглушек

Файлы: `State/MessagesStore.swift`, `Features/Chat/*`, `Features/ChatList/*`,
`Features/Chat/ChatFooter/*`, `Navigation/Route.swift`, `FEATURES/Profile`, `Settings`.

1. `MessagesStore` — на каждый чат (кэш по `chatID`) + репозиторий поверх
   `MessagingAPI`; `ChatView` использует `chat.id`.
2. Реальная отправка: `send(text:to:)` → оптимистичная вставка → подтверждение/ошибка
   от API; убрать `Bool.random()`, `"12:00"`, `chatId: 1`, `authorId: "user_1"`.
3. Фото: `PhotosPicker` → загрузка/вложение (или явное «скоро», без пустого стаба).
4. Голосовые: состояние `idle → recording → locked`, отмена/отправка, удаление файла,
   таймер и волна из реальных сэмплов.
5. Меню чата и списка: пункты либо реализованы (pin/mute/delete/поиск), либо скрыты.
   Убрать `print`-заглушки и хардкод «Nicolas Cage», `"2!#SEe3"`, `image: ""`.
6. `NewMessage`: реальный поиск через `searchUsers`, состояния empty/loading/error.
7. `Settings`/`Profile`: убрать мок-строки и вложенный `List`; реальные данные
   пользователя; `ProfileView` — из `Route.profile(id: userID)`, а не chatID.
8. `Router`: `pendingRoute` обрабатывать при появлении корневого экрана, а не только
   на `onDismiss`; убрать дубль `Route.chatList`.
9. Удалить мёртвые модели или использовать их; снять лишние `public`.

## 7. Этап 6 — UI/UX, доступность, локализация

1. String Catalog (`Localizable.xcstrings`), все строки — через ключи; убрать
   смесь русского и английского.
2. Accessibility: label/hint для всех icon-only кнопок, identifiers для UI-тестов,
   Dynamic Type (`.font(.headline)` вместо `.system(size:)`), `@ScaledMetric` для
   иконочных размеров.
3. `accessibilityReduceMotion` для кастомных переходов (zoom, blur, инверсия).
4. Состояния empty/loading/error для списка, поиска, чата, профиля.
5. `Theme`: переименовать вложенные типы в `Spacing/Radius/BorderWidth/Colors`
   (поэтапно, с обновлением вызовов), вынести магические числа, общий градиент,
   общие стили кнопок (`ScaleButtonStyle`, `InstantPressButtonStyle`).
6. `AvatarView`: убрать `.cornerRadius`, кэш и downsampling изображений, память под
   контроль, поддержка iPad-размеров.
7. Экраны Auth: единый glass-стиль, честные подписи («Continue with iCloud» →
   «Продолжить», если CloudKit нет), нормальные тексты ошибок по коду ошибки.
8. Превью: `#Preview` для каждой новой/изменённой вьюхи с реалистичными данными,
   оба цветовых режима.

## 8. Этап 7 — Структура и размеры файлов

1. Разбить `BloomManager.swift` (340), `BloomManagerModels.swift` (361),
   `UIKitContextMenu.swift` (232) по лимитам 150/250.
2. Один тип на файл: `ChatsListRowView`, `ChatPreviewView`, `VariableBlurView`,
   `MnemonicField`, `WaveBarItem`, `ScaleButtonStyle`, `InstantPressButtonStyle`,
   `ContextAction`.
3. `String.hexToBytes` → `Extensions/String+Hex.swift`, заменить на эффективное
   преобразование (`UInt8(hexString, radix: 16)` по парам, без конкатенации строк),
   ошибки вместо молчаливого отбрасывания.
4. Переименовать `EnviromentValues+Namespace.swift` → `EnvironmentValues+Namespace.swift`,
   `String+Custom`/`AnyTransition+Custom` → конкретные имена.
5. Убрать `// test test test (delete later)` и отладочные блоки.

## 9. Этап 8 — Тесты, CI, линтеры

1. Создать таргеты `BloomTests`, `BloomUITests`, `BloomPerformanceTests` и
   `Bloom.xctestplan` отдельным коммитом (правка `project.pbxproj`).
2. Покрыть: `Router`, валидацию мнемоники (BIP39-чексумма, 12 слов, NFKD),
   декодирование моделей и враждебный JSON, `MessagesStore`, обработку аудио,
   `UIColor(hex:)`, `hexToBytes`.
3. UI-тесты на `-AppMode=mock`: авторизация, список, отправка, навигация.
4. `.swiftlint.yml`, `.swiftformat`, `Scripts/check-file-size.sh`,
   `Scripts/security-audit.sh`; allowlist для файлов, которые ещё не разбиты.
5. CI (macOS runner): build Debug/Release, strict concurrency, lint, unit-тесты
   на симуляторе — только для CI, локальная проверка остаётся на устройстве.

## 10. Этап 9 — Репозиторий, сборка, документация

1. Коммитить `Package.resolved`: в `.gitignore` заменить
   `*.xcodeproj/project.xcworkspace/` на правило с исключением
   `!*.xcodeproj/project.xcworkspace/xcshareddata/`.
2. Выровнять `IPHONEOS_DEPLOYMENT_TARGET` (проект 26.2 vs таргет 26.0) — оставить
   26.0 в обоих местах.
3. Схема Run → Debug (сейчас Release); Release-сборка для архива.
4. Добавить иконку приложения и `AccentColor`; проверить `PrivacyInfo.xcprivacy`
   и `NSFaceIDUsageDescription` при внедрении биометрии.
5. Переписать README под фактическое состояние (Swift 5.0, iOS 26.0, реальный
   список зависимостей, отсутствие FaceID до этапа 1.6, корректный clone URL).
6. Добавить `AGENTS.md` в репозиторий (сейчас untracked) или удалить, если он
   локальный. `opencode.json` — в `.gitignore`.

## 11. Порядок и зависимости

| Этап | Зависит от | Риск |
|---|---|---|
| 1. Секреты | — | высокий, трогает Auth |
| 2. Падения | — | низкий |
| 3. Конкурентность | 1.3 (API-протоколы) | высокий, много файлов |
| 4. Производительность | — | средний, нужны замеры |
| 5. Реальные данные | 1.3, 3 | высокий |
| 6. UI/A11y | 5 | средний |
| 7. Структура | любой | низкий |
| 8. Тесты | 1, 2, 3 | средний |
| 9. Репозиторий | — | низкий |

Рекомендуемый первый коммит после этого документа: этап 2 (падения) — он маленький
и снимает самые дешёвые краши; сразу за ним этап 1 (секреты).

## 12. Чек-лист на каждый этап

- [ ] Debug и Release собираются без новых предупреждений.
- [ ] `SWIFT_STRICT_CONCURRENCY=complete` без новых диагностик в затронутом коде.
- [ ] Нет `print`, force unwrap/cast, магических цветов и строк в новом коде.
- [ ] Добавлены/обновлены тесты; регрессионный тест на исправленный дефект.
- [ ] Проверено на физическом устройстве (или явно указано, что не проверено).
- [ ] Для производительности — замеры до/после.
- [ ] Для MOCK — проверено, что API не инициализируется и сеть не вызывается.
