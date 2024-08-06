import { ExposedJsApi } from '../ExposedJsApi';
import { CordovaBridge } from '../CordovaBridge';
import { JavaScriptInterface } from '../Entity';

export class SystemExposedJsApi implements ExposedJsApi {
  bridge: CordovaBridge;
  methodList: Array<string>;

  constructor(bridge: CordovaBridge) {
    this.bridge = bridge;
    this.methodList = ['exec', 'setNativeToJsBridgeMode', 'retrieveJsMessages'];
  }

  @JavaScriptInterface()
  exec(bridgeSecret: number, service: string, action: string, callbackId: string, args: string): string | null {
    try {
      return this.bridge.jsExec(bridgeSecret, service, action, callbackId, args);
    } catch (error) {
      throw new Error(`Failed to execute: ${error}`);
    }
  }

  @JavaScriptInterface()
  setNativeToJsBridgeMode(bridgeSecret: number, value: number): void {
    try {
      this.bridge.jsSetNativeToJsBridgeMode(bridgeSecret, value);
    } catch (error) {
      throw new Error(`Failed to set bridge mode: ${error}`);
    }
  }

  @JavaScriptInterface()
  retrieveJsMessages(bridgeSecret: number, fromOnlineEvent: boolean): string | null {
    try {
      return this.bridge.jsRetrieveJsMessages(bridgeSecret, fromOnlineEvent);
    } catch (error) {
      throw new Error(`Failed to retrieve messages: ${error}`);
    }
  }
}