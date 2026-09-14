import { useEffect, useState } from 'react';

/** Arama kutularının gecikmesi. */
export const SEARCH_DEBOUNCE_MS = 300;

/**
 * Değeri, son değişiklikten `delayMs` sonra döndürür. Arama kutusunda her tuş vuruşu
 * ayrı istek atmasın: /api/v1/admin/** altındaki her istek denetim defterine düşüyor
 * (KURALLAR §1.3).
 */
export function useDebouncedValue<T>(value: T, delayMs: number): T {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delayMs);
    return () => clearTimeout(timer);
  }, [value, delayMs]);

  return debounced;
}
