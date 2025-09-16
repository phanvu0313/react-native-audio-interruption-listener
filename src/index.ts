import { NativeModules, NativeEventEmitter } from 'react-native';

export type Mode = 'record'|'play';
export type AndroidState = 'loss'|'loss_transient'|'duck'|'gain';
export type IOSState = 'began'|'ended';
export type Event = { platform: 'android'|'ios', state: AndroidState|IOSState };

const { RNAudioInterruption } = NativeModules;
const emitter = new NativeEventEmitter(RNAudioInterruption);

export function start(mode: Mode) { RNAudioInterruption.start(mode); }
export function stop() { RNAudioInterruption.stop(); }
export function addListener(cb: (e: Event)=>void) {
  const sub = emitter.addListener('audioInterruption', cb);
  return () => sub.remove();
}
