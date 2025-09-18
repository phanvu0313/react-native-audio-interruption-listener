"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.start = start;
exports.stop = stop;
exports.addListener = addListener;
exports.isBusy = isBusy;
const react_native_1 = require("react-native");
const { RNAudioInterruption } = react_native_1.NativeModules;
if (!RNAudioInterruption) {
    const LINKING_ERROR = 'react-native-audio-interruption-listener: Native module not found. ' +
        'Hãy chắc chắn rằng đã chạy "pod install" trong thư mục ios, ' +
        'đã rebuild ứng dụng và không dùng Expo managed.';
    throw new Error(LINKING_ERROR);
}
const emitter = new react_native_1.NativeEventEmitter(RNAudioInterruption);
function start(mode) { RNAudioInterruption.start(mode); }
function stop() { RNAudioInterruption.stop(); }
function addListener(cb) {
    const sub = emitter.addListener('audioInterruption', cb);
    return () => sub.remove();
}
function isBusy() {
    if (typeof RNAudioInterruption.isBusy !== 'function') {
        throw new Error('react-native-audio-interruption-listener: isBusy() không khả dụng. ' +
            'Hãy đảm bảo native code đã được build lại sau khi nâng cấp thư viện.');
    }
    return RNAudioInterruption.isBusy();
}
