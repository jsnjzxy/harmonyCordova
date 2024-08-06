export interface ExposedJsApi {
  exec(bridgeSecret: number, service: string, action: string, callbackId: string, args: string): string | null;
  setNativeToJsBridgeMode(bridgeSecret: number, value: number): void;
  retrieveJsMessages(bridgeSecret: number, fromOnlineEvent: boolean): string | null;
}