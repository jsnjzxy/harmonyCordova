import { CordovaPlugin, CordovaArgs, CallbackContext } from 'lib_cordova'

export class BMMessageChannelPlugin extends CordovaPlugin {

  execute(action: string, args: CordovaArgs, callbackContext: CallbackContext): boolean {
    switch (action) {
      case 'ready':
        return true;
      default:
        break;
    }
    return false;
  }
}