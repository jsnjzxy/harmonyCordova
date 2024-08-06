import { CordovaPlugin, CordovaArgs, CallbackContext } from 'lib_cordova'

export class BMDeviceInfoPlugin extends CordovaPlugin {

  execute(action: string, args: CordovaArgs, callbackContext: CallbackContext): boolean {
    switch (action) {
      case 'phoneInfo':
        let phoneInfo = JSON.stringify({
          'c': 131,
          'loc': JSON.stringify({
            'x': 123,
            'y': 456
          })
        });
        callbackContext.success(phoneInfo);
        return true;
      default:
        break;
    }
    return false;
  }

}