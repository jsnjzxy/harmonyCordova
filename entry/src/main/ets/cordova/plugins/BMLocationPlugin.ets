import { CordovaPlugin, CordovaArgs, CallbackContext } from 'lib_cordova'

export class BMLocationPlugin extends CordovaPlugin {

  execute(action: string, args: CordovaArgs, callbackContext: CallbackContext): boolean {
    switch (action) {
      case 'getLocation':
        let loc = JSON.stringify({
          'x': 123,
          'y': 456,
        });
        callbackContext.success(loc);
        return true;
      default:
        break;
    }
    return false;
  }
}