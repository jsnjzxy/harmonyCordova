import { CordovaWebViewProxy } from './CordovaWebViewProxy';
import { CordovaPlugin } from './CordovaPlugin';
import { PluginEntry } from './PluginEntry';
import { PluginResult, Status } from './PluginResult';
import { CallbackContext } from './CallbackContext';

export class PluginManager {
  private static readonly TAG = "PluginManager";
  private static readonly SCHEME_HTTPS = "https";
  private static readonly DEFAULT_HOSTNAME = "localhost";
  private static readonly SLOW_EXEC_WARNING_THRESHOLD = 16; // Assuming debugger is not connected

  private delegate: CordovaWebViewProxy;
  private pluginMap = new Map<string, CordovaPlugin>();
  private entryMap = new Map<string, PluginEntry>();

  private isInitialized: boolean = false;

  constructor(delegate: CordovaWebViewProxy, pluginEntries?: Array<PluginEntry>) {
    this.delegate = delegate;
    if (pluginEntries != null) {
      this.setPluginEntries(pluginEntries);
    }
  }

  setPluginEntries(pluginEntries: Array<PluginEntry>): void {
    if (this.isInitialized) {
      this.onPause();
      this.onDestroy();
      this.pluginMap.clear();
      this.entryMap.clear();
    }
    pluginEntries.forEach(entry => this.addServiceEntry(entry));
    if (this.isInitialized) {
      this.startupPlugins();
    }
  }

  init(): void {
    console.log(`${PluginManager.TAG}: init()`);
    this.isInitialized = true;
    this.onPause();
    this.onDestroy();
    this.pluginMap.clear();
    this.startupPlugins();
  }

  private startupPlugins(): void {
    this.entryMap.forEach(entry => {
      if (entry.onload) {
        this.getPlugin(entry.service);
      }
    });
  }

  exec(service: string, action: string, callbackId: string, rawArgs: string): void {
    const plugin = this.getPlugin(service);
    if (!plugin) {
      console.log(`exec() call to unknown plugin: ${service}`);
      const cr = new PluginResult(Status.CLASS_NOT_FOUND_EXCEPTION);
      this.delegate.sendPluginResult(cr, callbackId);
      return;
    }
    const callbackContext = new CallbackContext(callbackId, this.delegate);
    try {
      const pluginStartTime = Date.now();
      const wasValidAction = plugin.baseExecute(action, rawArgs, callbackContext);
      const duration = Date.now() - pluginStartTime;

      if (duration > PluginManager.SLOW_EXEC_WARNING_THRESHOLD) {
        console.warn(`THREAD WARNING: exec() call to ${service}.${action} blocked the main thread for ${duration}ms. Plugin should use CordovaInterface.getThreadPool().`);
      }
      if (!wasValidAction) {
        const cr = new PluginResult(Status.INVALID_ACTION);
        callbackContext.sendPluginResult(cr);
      }
    } catch (e) {
      console.error(`Uncaught exception from plugin`, e);
      callbackContext.error(e.message);
    }
  }

  getPlugin(service: string): CordovaPlugin | null {
    let plugin = this.pluginMap.get(service) as CordovaPlugin;
    if (!plugin) {
      const pe = this.entryMap.get(service);
      if (!pe) {
        return null;
      }
      if (pe.plugin) {
        plugin = pe.plugin ;
      }
      this.pluginMap.set(service, plugin);
    }
    return plugin;
  }

  addServiceEntry(entry: PluginEntry): void {
    this.entryMap.set(entry.service, entry);
    if (entry.plugin) {
      entry.plugin.privateInitialize(entry.service, this.delegate.controller, this.delegate.preferences);
      console.log(`addService: put - ${entry.service}`);
      this.pluginMap.set(entry.service, entry.plugin);
    }
  }

  onPause(): void {
    this.pluginMap.forEach(plugin => {
      plugin?.onPause();
    });
  }

  onResume(): void {
    this.pluginMap.forEach(plugin => {
      plugin?.onResume();
    });
  }

  onStart(): void {
    this.pluginMap.forEach(plugin => {
      plugin?.onStart();
    });
  }

  onStop(): void {
    this.pluginMap.forEach(plugin => {
      plugin?.onStop();
    });
  }

  onDestroy(): void {
    this.pluginMap.forEach(plugin => {
      plugin?.onDestroy();
    });
  }

  onNewWant(intent: ESObject): void {
    this.pluginMap.forEach(plugin => {
      plugin?.onNewWant(intent);
    });
  }

  onReset(): void {
    this.pluginMap.forEach(plugin => {
      plugin?.onReset();
    });
  }

  shouldAllowBridgeAccess(url: string): boolean {
    for (let entry of this.entryMap.values()) {
      let plugin = this.pluginMap.get(entry.service);
      if (plugin != null) {
        let result = plugin.shouldAllowBridgeAccess(url);
        if (result) {
          return result;
        }
      }
    }
    return false;
  }
}