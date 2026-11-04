import * as XLSX from 'xlsx';

/**
 * Exporte un tableau d'objets vers un fichier Excel natif (.xlsx)
 */
export function exportToExcel(
  data: Record<string, any>[],
  fileName: string,
  sheetName = 'Données'
) {
  if (!data || data.length === 0) {
    alert('Aucune donnée à exporter.');
    return;
  }

  const worksheet = XLSX.utils.json_to_sheet(data);
  const workbook = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(workbook, worksheet, sheetName);

  const cleanFileName = fileName.endsWith('.xlsx') ? fileName : `${fileName}.xlsx`;
  XLSX.writeFile(workbook, cleanFileName);
}

/**
 * Exporte un tableau d'objets vers un fichier CSV avec encodage UTF-8 BOM
 */
export function exportToCsv(data: Record<string, any>[], fileName: string) {
  if (!data || data.length === 0) {
    alert('Aucune donnée à exporter.');
    return;
  }

  const keys = Object.keys(data[0]);
  const csvRows: string[] = [];

  // Header row
  csvRows.push(keys.map((k) => `"${k.replace(/"/g, '""')}"`).join(';'));

  // Data rows
  for (const row of data) {
    const values = keys.map((k) => {
      const val = row[k] ?? '';
      return `"${String(val).replace(/"/g, '""')}"`;
    });
    csvRows.push(values.join(';'));
  }

  const csvString = '\uFEFF' + csvRows.join('\r\n');
  const blob = new Blob([csvString], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.setAttribute('href', url);
  link.setAttribute('download', fileName.endsWith('.csv') ? fileName : `${fileName}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}
