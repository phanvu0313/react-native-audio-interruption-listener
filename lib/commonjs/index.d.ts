export type Mode = 'record' | 'play';
export type AndroidState = 'loss' | 'loss_transient' | 'duck' | 'gain';
export type IOSState = 'began' | 'ended';
export type Event = {
    platform: 'android' | 'ios';
    state: AndroidState | IOSState;
};
export declare function start(mode: Mode): void;
export declare function stop(): void;
export declare function addListener(cb: (e: Event) => void): () => void;
export declare function isBusy(): Promise<boolean>;
