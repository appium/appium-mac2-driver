export function clearArray<T>(items: T[]): void {
  items.length = 0;
}

export function removeAllOccurrences<T>(items: T[], value: T): void {
  let index = items.indexOf(value);
  while (index >= 0) {
    items.splice(index, 1);
    index = items.indexOf(value);
  }
}

export function isPlainObject(value: unknown): value is Record<string, unknown> {
  if (value === null || typeof value !== 'object') {
    return false;
  }
  const proto = Object.getPrototypeOf(value);
  return proto === Object.prototype || proto === null;
}
