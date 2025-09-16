"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.start = start;
exports.stop = stop;
exports.addListener = addListener;
const react_native_1 = require("react-native");
const { RNAudioInterruption } = react_native_1.NativeModules;
const emitter = new react_native_1.NativeEventEmitter(RNAudioInterruption);
function start(mode) { RNAudioInterruption.start(mode); }
function stop() { RNAudioInterruption.stop(); }
function addListener(cb) {
    const sub = emitter.addListener('audioInterruption', cb);
    return () => sub.remove();
}
