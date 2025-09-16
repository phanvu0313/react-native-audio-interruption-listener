# react-native-audio-interruption-listener

**Lightweight listener for audio focus / AVAudioSession interruptions (Android/iOS).**

-   Old Architecture friendly (RN ≥ 0.60). Tested on RN **0.66.4** & **0.74**.
-   Không yêu cầu quyền cuộc gọi (CALL/PHONE).
-   Chỉ giữ audio focus khi bạn `start()`; giải phóng ở `stop()`.

> Use case chuẩn: tự **pause/resume** `react-native-audio-recorder-player` khi có GSM call/VoIP/alarm/app khác chiếm audio.

---

## Cài đặt

```bash
npm i react-native-audio-interruption-listener react-native-audio-recorder-player
# hoặc
yarn add react-native-audio-interruption-listener react-native-audio-recorder-player

# iOS
cd ios && pod install && cd ..
```

> **RN 0.66.x**: nếu iOS build lỗi do Flipper, bạn có thể comment `use_flipper!` trong Podfile, `pod deintegrate && pod install --repo-update`.

---

## API

```ts
import { start, stop, addListener } from "react-native-audio-interruption-listener"
```

-   `start(mode: 'record' | 'play')`: Bắt đầu lắng nghe interruption (và lịch sự claim audio focus/activate session theo mode).
-   `stop()`: Dừng lắng nghe (abandon audio focus / setActive(false)).
-   `addListener(cb)`: Nhận callback `{ platform: 'android'|'ios', state }`.

### States

-   **Android**: `loss | loss_transient | duck | gain`
-   **iOS**: `began | ended`

> Gợi ý map nhanh:
>
> -   Bất kỳ `loss/loss_transient/duck/began` → _pause_.
> -   `gain/ended` → _resume_ (tuỳ logic của bạn).

---

## Quick Start với `react-native-audio-recorder-player`

### Demo tối giản (playback & record)

```tsx
import React, { useEffect, useRef, useState } from "react"
import { SafeAreaView, Text, Button, Platform } from "react-native"
import { start, stop, addListener } from "react-native-audio-interruption-listener"
import AudioRecorderPlayer from "react-native-audio-recorder-player"

const arp = new AudioRecorderPlayer()

export default function App() {
    const unsubRef = useRef<() => void>()
    const [lastEvt, setLastEvt] = useState("—")

    useEffect(() => {
        unsubRef.current = addListener(({ platform, state }) => {
            console.log("[audioInterruption]", platform, state)
            setLastEvt(`${platform}:${state}`)
            // Pause/resume theo state
            if (platform === "android") {
                if (state === "loss" || state === "loss_transient" || state === "duck") {
                    arp.pauseRecorder().catch(() => {})
                    arp.pausePlayer().catch(() => {})
                } else if (state === "gain") {
                    arp.resumeRecorder().catch(() => {})
                    arp.resumePlayer().catch(() => {})
                }
            } else {
                if (state === "began") {
                    arp.pauseRecorder().catch(() => {})
                    arp.pausePlayer().catch(() => {})
                } else if (state === "ended") {
                    arp.resumeRecorder().catch(() => {})
                    arp.resumePlayer().catch(() => {})
                }
            }
        })
        return () => unsubRef.current?.()
    }, [])

    return (
        <SafeAreaView style={{ padding: 24 }}>
            <Text style={{ fontSize: 18, fontWeight: "600" }}>Audio Interruption Demo</Text>
            <Text style={{ marginVertical: 12 }}>Last event: {lastEvt}</Text>

            <Button title="Start (play mode)" onPress={() => start("play")} />
            <Button title="Start (record mode)" onPress={() => start("record")} />
            <Button title="Stop" color="tomato" onPress={() => stop()} />

            <Text style={{ marginTop: 12, opacity: 0.7 }}>{Platform.OS === "ios" ? "iOS: began/ended" : "Android: loss/loss_transient/duck/gain"}</Text>
        </SafeAreaView>
    )
}
```

### Recipe: **Record flow** gọn gàng

```ts
async function beginRecord() {
    start("record")
    await arp.startRecorder()
}
async function endRecord() {
    await arp.stopRecorder()
    stop()
}
```

### Recipe: **Playback flow** gọn gàng

```ts
async function beginPlay(path: string) {
    start("play")
    await arp.startPlayer(path)
}
async function endPlay() {
    await arp.stopPlayer()
    stop()
}
```

> Mẹo: chỉ `start()` **ngay trước** khi record/play và `stop()` **ngay sau** khi dừng để không giữ focus 24/7.

---

## Hành vi nền tảng

### Android

-   Dùng **Audio Focus**: báo về `loss`, `loss_transient`, `duck`, `gain`.
-   `mode: 'record'` → ưu tiên `USAGE_VOICE_COMMUNICATION` + `CONTENT_TYPE_SPEECH`.
-   `mode: 'play'` → `USAGE_MEDIA` + `CONTENT_TYPE_MUSIC`.
-   Không cần permission cuộc gọi.

### iOS

-   Dùng **AVAudioSession** interruption: báo `began/ended`.
-   `'record'` → `PlayAndRecord` (+ `DuckOthers`, `DefaultToSpeaker`).
-   `'play'` → `Playback` (+ `DuckOthers`).
-   Không cần quyền đặc biệt. **Device thật** mới test được cuộc gọi.

---

## Test interruption nhanh

-   **Android**: gọi vào máy, bật alarm, mở app khác phát nhạc → xem log JS.
-   **iOS (device thật)**: gọi vào máy → `began` khi đổ chuông, `ended` khi dập máy.
-   Simulator iOS **không** test được cuộc gọi.

---

## Troubleshooting

### iOS – Flipper pod lỗi (RN 0.66.x)

-   Comment `use_flipper!` trong `ios/Podfile`, rồi:

    ```bash
    cd ios
    pod deintegrate
    rm -rf Pods Podfile.lock
    pod install --repo-update
    cd ..
    ```

### Android – Kotlin/SDK lỗi khi tích hợp lib riêng

-   `Plugin with id 'kotlin-android' not found`: thêm vào `android/build.gradle` của **lib**:

    ```gradle
    buildscript {
      ext.kotlin_version = '1.6.10'
      repositories { google(); mavenCentral() }
      dependencies { classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version" }
    }
    apply plugin: 'kotlin-android'
    ```

-   `compileSdkVersion is not specified`: trong `android {}`, đặt `compileSdkVersion 31` (khớp RN 0.66.x) hoặc theo app của bạn.

### Không thấy event?

-   Đã gọi `start('play'|'record')` trước khi phát/ghi chưa?
-   Đang test trên **device thật** (đặc biệt iOS) chưa?
-   App khác thực sự phát audio/có cuộc gọi/chuông báo chưa?

---

## Tương thích & yêu cầu

-   React Native: **≥ 0.60** (Old Architecture). Tested: **0.66.4**, **0.74**.
-   Android: **minSdk 21**, compile/target khuyên dùng **31** cho RN 0.66.x.
-   iOS: **iOS 11+**.

---

## Notes hay ho

-   Bạn có thể chọn **không auto-resume** sau khi `gain/ended` (chờ user bấm tiếp tục).
-   Có thể debounce event nếu UI của bạn nhạy cảm (ví dụ liên tiếp `duck` → `gain`).
-   Với recorder, cân nhắc lưu trạng thái (đang ghi/đang phát) để resume đúng hàm.

---

## Giấy phép

MIT
