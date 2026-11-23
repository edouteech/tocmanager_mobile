export function sanitizeCell(value: unknown): string | number {
  if (value === null || value === undefined) return '';
  if (typeof value === 'number') return Number.isFinite(value) ? value : '';
  if (typeof value === 'boolean') return value ? 'Oui' : 'Non';
  const text = String(value);
  if (/^[=+\-@\t\r]/.test(text.trimStart())) {
    return `'${text}`;
  }
  return text;
}

export function formatCsvCell(value: unknown): string {
  const sanitized = sanitizeCell(value);
  return `"${String(sanitized).replace(/"/g, '""')}"`;
}

export function downloadCsvContent(csvBody: string, fileName: string): void {
  const bomContent = `\uFEFF${csvBody}`;
  const blob = new Blob([bomContent], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  try {
    link.setAttribute('href', url);
    link.setAttribute('download', fileName.endsWith('.csv') ? fileName : `${fileName}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  } finally {
    window.setTimeout(() => URL.revokeObjectURL(url), 1000);
  }
}

export async function exportToExcel(
  data: Record<string, unknown>[],
  fileName: string,
  sheetName = 'Données'
): Promise<boolean> {
  if (!data || data.length === 0) {
    return false;
  }

  const ExcelJS = (await import('exceljs')).default;
  const workbook = new ExcelJS.Workbook();
  const safeSheetName = sheetName.replace(/[\\/?*[\]:]/g, ' ').slice(0, 31) || 'Données';
  const worksheet = workbook.addWorksheet(safeSheetName);

  const headers = Object.keys(data[0]);
  const headerRow = worksheet.addRow(headers.map((h) => sanitizeCell(h)));
  headerRow.font = { bold: true };

  for (const row of data) {
    worksheet.addRow(headers.map((header) => sanitizeCell(row[header])));
  }

  headers.forEach((header, idx) => {
    const column = worksheet.getColumn(idx + 1);
    const maxLen = Math.min(
      45,
      Math.max(
        header.length + 4,
        ...data.slice(0, 100).map((r) => String(r[header] ?? '').length + 2)
      )
    );
    column.width = Math.max(12, maxLen);
  });

  const buffer = await workbook.xlsx.writeBuffer();
  const blob = new Blob([buffer], {
    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  try {
    link.setAttribute('href', url);
    link.setAttribute('download', fileName.endsWith('.xlsx') ? fileName : `${fileName}.xlsx`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  } finally {
    window.setTimeout(() => URL.revokeObjectURL(url), 1000);
  }
  return true;
}

export function exportToCsv(data: Record<string, unknown>[], fileName: string): boolean {
  if (!data || data.length === 0) {
    return false;
  }

  const keys = Object.keys(data[0]);
  const csvRows: string[] = [keys.map((k) => formatCsvCell(k)).join(';')];
  for (const row of data) {
    csvRows.push(keys.map((k) => formatCsvCell(row[k])).join(';'));
  }

  downloadCsvContent(csvRows.join('\r\n'), fileName);
  return true;
}
