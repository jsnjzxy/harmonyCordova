import { CordovaWebViewProxyImpl } from 'lib_cordova';
import { BMCordovaPluginFactory } from './BMCordovaPluginFactory';
import webview from '@ohos.web.webview';

export class BMCordovaWebViewProxy extends CordovaWebViewProxyImpl {

  static createController(): BMCordovaWebViewProxy {
    return new BMCordovaWebViewProxy(new webview.WebviewController(), BMCordovaPluginFactory.pluginEntries());
  }
}