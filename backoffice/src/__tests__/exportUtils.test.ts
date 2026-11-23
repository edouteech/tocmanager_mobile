import { afterEach, describe, expect, it, vi } from 'vitest';
import { exportToCsv, formatCsvCell, sanitizeCell } from '../lib/exportUtils';

describe('exportUtils', () => {
  afterEach(() => {
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  it('neutralizes CSV/Excel formula injection payloads', () => {
    expect(sanitizeCell('=SUM(A1:A2)')).toBe("'=SUM(A1:A2)");
    expect(sanitizeCell('+1+1')).toBe("'+1+1");
    expect(sanitizeCell('-100')).toBe("'-100");
    expect(sanitizeCell('@cmd')).toBe("'@cmd");
    expect(sanitizeCell('  =HYPERLINK("http://evil")')).toBe('\'  =HYPERLINK("http://evil")');
    expect(sanitizeCell('\t=1+2')).toBe("'\t=1+2");
  });

  it('preserves safe primitives and normalizes booleans/nullish values', () => {
    expect(sanitizeCell(null)).toBe('');
    expect(sanitizeCell(undefined)).toBe('');
    expect(sanitizeCell(Number.NaN)).toBe('');
    expect(sanitizeCell(1250)).toBe(1250);
    expect(sanitizeCell(true)).toBe('Oui');
    expect(sanitizeCell(false)).toBe('Non');
    expect(sanitizeCell('Savon Noir')).toBe('Savon Noir');
  });

  it('escapes quotes in CSV cells', () => {
    expect(formatCsvCell('Produit "Pro"')).toBe('"Produit ""Pro"""');
    expect(formatCsvCell('=1+1')).toBe('"\'=1+1"');
  });

  it('returns false when exporting an empty array', () => {
    expect(exportToCsv([], 'empty.csv')).toBe(false);
  });

  it('creates a UTF-8 BOM CSV blob, triggers download and revokes URL', async () => {
    vi.useFakeTimers();
    const createObjectURL = vi.fn(() => 'blob:mock-csv');
    const revokeObjectURL = vi.fn();
    Object.defineProperty(URL, 'createObjectURL', { value: createObjectURL, configurable: true });
    Object.defineProperty(URL, 'revokeObjectURL', { value: revokeObjectURL, configurable: true });

    const clickSpy = vi.fn();
    const origCreateElement = document.createElement.bind(document);
    vi.spyOn(document, 'createElement').mockImplementation((tagName: string) => {
      const el = origCreateElement(tagName);
      if (tagName === 'a') {
        vi.spyOn(el as HTMLAnchorElement, 'click').mockImplementation(clickSpy);
      }
      return el;
    });

    const result = exportToCsv(
      [{ Nom: '=cmd', Prix: 1500 }],
      'produits'
    );

    expect(result).toBe(true);
    expect(createObjectURL).toHaveBeenCalledTimes(1);
    const blobArg = (createObjectURL.mock.calls[0] as unknown[])[0] as Blob;
    expect(blobArg).toBeInstanceOf(Blob);
    expect(clickSpy).toHaveBeenCalledTimes(1);

    vi.advanceTimersByTime(1000);
    expect(revokeObjectURL).toHaveBeenCalledWith('blob:mock-csv');
    vi.useRealTimers();

    const blobBuffer = await new Promise<ArrayBuffer>((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result as ArrayBuffer);
      reader.onerror = () => reject(reader.error);
      reader.readAsArrayBuffer(blobArg);
    });
    const bytes = new Uint8Array(blobBuffer);
    expect(Array.from(bytes.slice(0, 3))).toEqual([0xef, 0xbb, 0xbf]);
    const blobText = new TextDecoder().decode(bytes.slice(3));
    expect(blobText).toContain('"\'=cmd";"1500"');
  });
});
