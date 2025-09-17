"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.start = start;
exports.stop = stop;
exports.addListener = addListener;
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
