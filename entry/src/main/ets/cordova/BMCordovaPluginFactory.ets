import { HashMap } from '@kit.ArkTS';
import { CordovaPlugin, PluginEntry } from 'lib_cordova';
import { BMDeviceInfoPlugin } from './plugins/BMDeviceInfoPlugin';
import { BMLocationPlugin } from './plugins/BMLocationPlugin';

export class BMCordovaPluginFactory {
  private static mPluginClassMap: HashMap<string, () => CordovaPlugin>;

  static {
    let pluginClassMap = new HashMap<string, () => CordovaPlugin>();
    pluginClassMap.set('DeviceInfo', () => new BMDeviceInfoPlugin);
    pluginClassMap.set('Location', () => new BMLocationPlugin);

    BMCordovaPluginFactory.mPluginClassMap = pluginClassMap;
  }

  static pluginEntries(): Array<PluginEntry> {
    let pluginEntries: Array<PluginEntry> = [];
    BMCordovaPluginFactory.mPluginClassMap.forEach((value, key) => {
      if (value != null && key != null) {
        let entity = new PluginEntry(key, true, value(), key);
        pluginEntries.push(entity) ;
      }
    });
		return pluginEntries;
	}
}