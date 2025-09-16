declare module 'react-native' {
  export const NativeModules: any;
  export class NativeEventEmitter {
    constructor(module?: any);
    addListener(eventType: string, listener: (...args:any[]) => void): { remove(): void };
    removeAllListeners?(eventType?: string): void;
  }
}
