import { CallbackContext } from './CallbackContext';
import { CordovaPreferences } from './CordovaPreferences';
import { CordovaArgs, ArgsType }from './CordovaArgs'
import { Configuration } from '@kit.ArkUI';
import Want from '@ohos.app.ability.Want';
import { webview } from '@kit.ArkWeb';

export class CordovaPlugin {
  controller: webview.WebviewController = new webview.WebviewController();
  preferences: CordovaPreferences = new CordovaPreferences();
  serviceName: string = '';

  privateInitialize(serviceName: string, controller: webview.WebviewController, preferences: CordovaPreferences) {
    this.serviceName = serviceName;
    this.controller = controller;
    this.preferences = preferences;
    this.pluginInitialize();
  }

  pluginInitialize() {
    // Plugin initialization code here
  }

  getServiceName(): string {
    return this.serviceName;
  }

  baseExecute(action: string, args: string | Array<object> | CordovaArgs, callbackContext: CallbackContext): boolean {
    let ret = false;
    if (typeof args == 'string') {
      ret = this.execute(action, JSON.parse(args), callbackContext);
    } else if (args instanceof CordovaArgs) {
      ret = this.execute(action, args, callbackContext);
    } else {
      let cordovaArgs = new CordovaArgs(args);
      ret = this.execute(action, cordovaArgs, callbackContext);
    }
    return ret;
  }

  execute(action: string, args: CordovaArgs, callbackContext: CallbackContext): boolean {
    return false;
  }

  onPause() {

  }

  onResume() {
    // Handle resume event
  }

  onStart() {
    // Handle start event
  }

  onStop() {
    // Handle stop event
  }

  onNewWant(intent: Want) {
    // Handle new intent
  }

  onDestroy() {
    // Handle destroy event
  }

  onReset() {
    // Handle reset event
  }

  onMessage(id: string, data: object): object {
    return new Object;
  }

  onOverrideUrlLoading(url: string): boolean {

    return false;
  }

  onConfigurationChanged(newConfig: Configuration) {

  }

  requestPermissions(requestCode: number) {

  }

  hasPermission(): boolean {
    return true;
  }

  onRequestPermissionsResult(requestCode: number, permissions: string[], grantResults: number[]) {

  }

  shouldAllowNavigation(url: string): boolean {
    return false;
  }

  shouldAllowBridgeAccess(url: string): boolean {
    return this.shouldAllowNavigation(url);
  }
}