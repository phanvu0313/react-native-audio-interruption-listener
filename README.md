# react-native-audio-interruption-listener

Thư viện giúp ứng dụng React Native nhận biết khi âm thanh bị gián đoạn do cuộc gọi, báo thức hoặc ứng dụng khác. Hoạt động tốt với React Native ≥ 0.60 (Old Architecture). Đã thử trên RN 0.66.4 và 0.74. Không yêu cầu quyền cuộc gọi. Thư viện chỉ giữ audio focus khi gọi `start()` và trả lại ngay khi `stop()`.

---

## Cài đặt nhanh

```bash
npm i react-native-audio-interruption-listener react-native-audio-recorder-player
# hoặc
yarn add react-native-audio-interruption-listener react-native-audio-recorder-player

# iOS
cd ios && pod install && cd ..
```

> Nếu dùng RN 0.66.x và gặp lỗi Flipper trên iOS, comment `use_flipper!` trong Podfile rồi chạy:
>
> ```bash
> cd ios
> pod deintegrate
> pod install --repo-update
> cd ..
> ```

---

## API chính

```ts
import { start, stop, addListener, isBusy } from "react-native-audio-interruption-listener"
```

-   `start(mode: 'record' | 'play')`: Bắt đầu lắng nghe và xin audio focus/session theo chế độ.
-   `stop()`: Dừng lắng nghe và trả audio focus/session lại hệ thống.
-   `addListener(cb)`: Nhận callback `{ platform: 'android' | 'ios', state }` mỗi khi có sự kiện.
-   `isBusy(): Promise<boolean>`: Kiểm tra nhanh xem thiết bị đang bận (cuộc gọi, VoIP, audio ưu tiên khác) để quyết định có nên ghi âm/phát ngay hay không.

Giá trị `state`:

-   Android: `loss`, `loss_transient`, `duck`, `gain`
-   iOS: `began`, `ended`

Gợi ý: xem `loss/loss_transient/duck/began` là pause, `gain/ended` là resume (tuỳ logic riêng).

---

## Ví dụ tối giản với react-native-audio-recorder-player

```tsx
import React, { useEffect } from "react"
import { Button, SafeAreaView } from "react-native"
import { start, stop, addListener, isBusy } from "react-native-audio-interruption-listener"
import AudioRecorderPlayer from "react-native-audio-recorder-player"

const arp = new AudioRecorderPlayer()

export default function App() {
    useEffect(() => {
        const unsubscribe = addListener(({ platform, state }) => {
            const pause = () => {
                arp.pauseRecorder().catch(() => {})
                arp.pausePlayer().catch(() => {})
            }
            const resume = () => {
                arp.resumeRecorder().catch(() => {})
                arp.resumePlayer().catch(() => {})
            }

            if (platform === "android") {
                state === "gain" ? resume() : pause()
            } else {
                state === "ended" ? resume() : pause()
            }
        })

        return () => unsubscribe()
    }, [])

    return (
        <SafeAreaView style={{ padding: 20 }}>
            <Button
                title="Start (play)"
                onPress={async () => {
                    if (await isBusy()) {
                        return
                    }
                    start("play")
                }}
            />
            <Button
                title="Start (record)"
                onPress={async () => {
                    if (await isBusy()) {
                        return
                    }
                    start("record")
                }}
            />
            <Button title="Stop" onPress={() => stop()} />
        </SafeAreaView>
    )
}
```

Công thức ngắn:

```ts
// Ghi âm
if (!(await isBusy())) {
    await Promise.all([start("record"), arp.startRecorder()])
    // ...
    await arp.stopRecorder()
    stop()
}

// Phát lại
if (!(await isBusy())) {
    await Promise.all([start("play"), arp.startPlayer(path)])
    // ...
    await arp.stopPlayer()
    stop()
}
```

Nên gọi `start()` ngay trước khi phát/ghi và `stop()` ngay sau khi dừng để không giữ audio focus quá lâu.

---

## Kiểm tra nhanh

-   Android: gọi điện, bật báo thức hoặc mở ứng dụng khác phát nhạc để xem sự kiện trả về.
-   iOS: thử trên thiết bị thật (Simulator không giả lập được cuộc gọi).

---

## Tương thích

-   React Native: ≥ 0.60 (Old Architecture)
-   Android: minSdk 21 (với RN 0.66.x nên đặt compile/target 31)
-   iOS: iOS 11 trở lên

---

## Khắc phục sự cố

-   Không nhận được sự kiện: chắc chắn đã gọi `start('play' | 'record')` và đang thử trên thiết bị thật với iOS.
-   Android khi tích hợp vào thư viện tự viết:
    ```gradle
    buildscript {
      ext.kotlin_version = '1.6.10'
      repositories { google(); mavenCentral() }
      dependencies { classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version" }
    }
    apply plugin: 'kotlin-android'
    android { compileSdkVersion 31; defaultConfig { targetSdkVersion 31; minSdkVersion 21 } }
    ```
-   Lỗi Flipper trên RN 0.66.x: comment `use_flipper!`, chạy `pod deintegrate && pod install --repo-update`.
-   iOS không autolink được (pod không xuất hiện trong `Podfile.lock`):
    1. Chạy `npx react-native config | grep react-native-audio-interruption-listener -n` để chắc chắn CLI đã đọc được `react-native.config.js`.
    2. Nếu vẫn không có, thêm thủ công vào `ios/Podfile` của app:
       ```ruby
       pod 'react-native-audio-interruption-listener', :path => '../node_modules/react-native-audio-interruption-listener'
       ```
       rồi `pod install`.
    3. Sau khi cài pod, rebuild app (không dùng `expo go`). Nếu Metro báo `Native module not found`, xoá DerivedData + cache, chạy lại `npx pod-install`.

---

## Giấy phép

MIT
