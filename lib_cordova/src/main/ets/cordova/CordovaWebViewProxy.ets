import webview from '@ohos.web.webview';
import { CordovaBridge } from './CordovaBridge';
import { CordovaPreferences } from './CordovaPreferences';
import { JsInterface } from './Entity';
import { NativeToJsMessageQueue } from './NativeToJsMessageQueue';
import { PluginManager } from './PluginManager';
import { PluginResult } from './PluginResult';

export interface CordovaWebViewProxy {
  controller: webview.WebviewController;
  bridge: CordovaBridge;
  pluginManager: PluginManager;
  preferences: CordovaPreferences;
  nativeToJsMessageQueue: NativeToJsMessageQueue;

  sendPluginResult(cr: PluginResult, callbackId: string): void;

  loadUrl(url: string): void;

  runJavaScript(script: string): Promise<string>;

  refresh(): void;

  getWebViewController(): webview.WebviewController;
}

export interface JavaScriptProxyInterface {
  object: JsInterface,
  name: string,
  methodList: Array<string>,
  controller: CordovaWebViewProxy
}