export class CordovaPreferences {
  private preferences: Map<string, string> = new Map<string, string>();

  set(name: string, value: string | boolean | number): void {
    if (typeof value === 'boolean' || typeof value === 'number') {
      value = String(value);
    }
    this.preferences.set(name.toLowerCase(), value);
  }

  getAll(): Map<string, string> {
    return new Map(this.preferences);
  }

  getBoolean(name: string, defaultValue: boolean): boolean {
    name = name.toLowerCase();
    const value = this.preferences.get(name);
    return value !== undefined ? value.toLowerCase() === 'true' : defaultValue;
  }

  contains(name: string): boolean {
    return this.preferences.has(name.toLowerCase());
  }

  getInteger(name: string, defaultValue: number): number {
    name = name.toLowerCase();
    const value = this.preferences.get(name);
    if (value !== undefined) {
      return parseInt(value, 10);
    }
    return defaultValue;
  }

  getDouble(name: string, defaultValue: number): number {
    name = name.toLowerCase();
    const value = this.preferences.get(name);
    if (value !== undefined) {
      return parseFloat(value);
    }
    return defaultValue;
  }

  getString(name: string, defaultValue: string | null): string | null {
    name = name.toLowerCase();
    const value = this.preferences.get(name);
    return value !== undefined ? value : defaultValue;
  }
}