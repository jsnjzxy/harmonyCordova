import { Context } from '@ohos.arkui.UIContext';
import { Ability, Want } from '@kit.AbilityKit';
import { CordovaPlugin } from './CordovaPlugin';

export interface CordovaInterface {
  /**
   * Launch an activity (or an equivalent task) for which you would like a result when it finishes.
   * When this activity exits, your onActivityResult() method will be called.
   * @param command The command object
   * @param intent The "intent" or action to start
   * @param requestCode The request code that is passed to callback to identify the activity
   */
  startActivityForResult(command: CordovaPlugin, intent: Want, requestCode: number): void;

  /**
   * Set the plugin to be called when a sub-activity (or task) exits.
   * @param plugin The plugin on which onActivityResult is to be called
   */
  setActivityResultCallback(plugin: CordovaPlugin): void;

  /**
   * Get the Ability context. Depending on the environment, this could be undefined.
   * @return The activity context or undefined if not applicable.
   */
  getAbility(): Ability;

  /**
   * Get the context. This is similar to getActivity but might be more general.
   * @return The context
   */
  getContext(): Context;

  /**
   * Called when a message is sent to plugin.
   * @param id The message id
   * @param data The message data
   * @return Object or null
   */
  onMessage(id: string, data: object): object;

  /**
   * Sends a permission request to the activity for one permission.
   */
  requestPermission(plugin: CordovaPlugin, requestCode: number, permission: string): void;

  /**
   * Sends a permission request to the activity for a group of permissions
   */
  requestPermissions(plugin: CordovaPlugin, requestCode: number, permissions: string[]): void;

  /**
   * Check for a permission. Returns true if the permission is granted, false otherwise.
   */
  hasPermission(permission: string): boolean;
}