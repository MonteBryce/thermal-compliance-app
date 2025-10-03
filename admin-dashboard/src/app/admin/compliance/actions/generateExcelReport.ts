'use server';

import { getAdminFirestore, getAdminStorage } from '@/lib/firebase-admin';
import { cookies } from 'next/headers';
import { validateAdminSession } from '@/lib/auth-utils';
import ExcelJS from 'exceljs';
import { LogEntry } from '@/lib/compliance-utils';
import { entriesCollectionRef, logsCollectionRef, projectDocRef } from '@/lib/firestore/paths';

interface ReportData {
  projectInfo: {
    projectId: string;
    facility: string;
    tankId: string;
    logType: string;
    startDate: Date;
    endDate: Date;
    customer: string;
    permitNumber: string;
  };
  entries: LogEntry[];
  summary: {
    totalHours: number;
    avgExhaustTemp: number;
    avgFlow: number;
    totalEmissions?: number;
    maxH2s?: number;
    maxBenzene?: number;
  };
  deviations: Array<{
    dateTime: Date;
    type: string;
    description: string;
    status: string;
  }>;
}

export async function generateExcelReport(
  projectId: string,
  logId: string,
  startDate: Date,
  endDate: Date
): Promise<{
  url: string;
  fileName: string;
  bytes: number;
}> {
  const cookieStore = await cookies();
  const session = await validateAdminSession(cookieStore);
  
  if (!session || session.role !== 'admin') {
    throw new Error('Unauthorized: Admin access required');
  }

  const db = getAdminFirestore();
  const storage = getAdminStorage();
  
  try {
    // Fetch project data
    const projectDoc = await projectDocRef(projectId).get();
    if (!projectDoc.exists) {
      throw new Error('Project not found');
    }
    const projectData = projectDoc.data()!;
    
    // Fetch log entries
    const entriesSnapshot = await entriesCollectionRef(projectId, logId)
      .where('timestamp', '>=', startDate)
      .where('timestamp', '<=', endDate)
      .orderBy('timestamp')
      .get();
    
    const entries: LogEntry[] = entriesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    } as LogEntry));
    
    // Fetch deviations
    const deviationsSnapshot = await db
      .collection('projects')
      .doc(projectId)
      .collection('deviations')
      .where('dateTime', '>=', startDate)
      .where('dateTime', '<=', endDate)
      .get();
    
    const deviations = deviationsSnapshot.docs.map(doc => ({
      ...doc.data(),
      dateTime: doc.data().dateTime?.toDate(),
    }));
    
    // Calculate summary statistics
    const summary = calculateSummary(entries);
    
    // Create Excel workbook
    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'Thermal Log Compliance System';
    workbook.created = new Date();
    
    // Add main data sheet
    const dataSheet = workbook.addWorksheet('Thermal Log Data');
    
    // Add header information
    dataSheet.mergeCells('A1:H1');
    dataSheet.getCell('A1').value = 'THERMAL LOG REPORT';
    dataSheet.getCell('A1').font = { size: 16, bold: true };
    dataSheet.getCell('A1').alignment = { horizontal: 'center' };
    
    // Project information
    dataSheet.getCell('A3').value = 'Project ID:';
    dataSheet.getCell('B3').value = projectData.projectId;
    dataSheet.getCell('D3').value = 'Facility:';
    dataSheet.getCell('E3').value = projectData.facility;
    dataSheet.getCell('G3').value = 'Tank ID:';
    dataSheet.getCell('H3').value = projectData.tankId;
    
    dataSheet.getCell('A4').value = 'Log Type:';
    dataSheet.getCell('B4').value = projectData.logType;
    dataSheet.getCell('D4').value = 'Customer:';
    dataSheet.getCell('E4').value = projectData.customer;
    dataSheet.getCell('G4').value = 'Permit #:';
    dataSheet.getCell('H4').value = projectData.permitNumber;
    
    dataSheet.getCell('A5').value = 'Report Period:';
    dataSheet.getCell('B5').value = `${startDate.toLocaleDateString()} - ${endDate.toLocaleDateString()}`;
    
    // Add data headers based on log type
    const headers = getHeadersForLogType(projectData.logType);
    dataSheet.getRow(7).values = headers;
    dataSheet.getRow(7).font = { bold: true };
    dataSheet.getRow(7).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFE0E0E0' },
    };
    
    // Add data rows
    let rowNum = 8;
    entries.forEach(entry => {
      const row = dataSheet.getRow(rowNum);
      row.values = formatEntryRow(entry, projectData.logType);
      
      // Highlight outliers or issues
      if (entry.h2sPpm && entry.h2sPpm > 10) {
        row.getCell(headers.indexOf('H2S (ppm)') + 1).fill = {
          type: 'pattern',
          pattern: 'solid',
          fgColor: { argb: 'FFFFCCCC' },
        };
      }
      
      rowNum++;
    });
    
    // Add summary section
    const summaryStartRow = rowNum + 2;
    dataSheet.getCell(`A${summaryStartRow}`).value = 'SUMMARY';
    dataSheet.getCell(`A${summaryStartRow}`).font = { bold: true, size: 14 };
    
    dataSheet.getCell(`A${summaryStartRow + 1}`).value = 'Total Hours:';
    dataSheet.getCell(`B${summaryStartRow + 1}`).value = summary.totalHours;
    dataSheet.getCell(`A${summaryStartRow + 2}`).value = 'Avg Exhaust Temp (°F):';
    dataSheet.getCell(`B${summaryStartRow + 2}`).value = summary.avgExhaustTemp;
    dataSheet.getCell(`A${summaryStartRow + 3}`).value = 'Avg Flow (scfh):';
    dataSheet.getCell(`B${summaryStartRow + 3}`).value = summary.avgFlow;
    
    if (summary.totalEmissions !== undefined) {
      dataSheet.getCell(`A${summaryStartRow + 4}`).value = 'Total Emissions (lb):';
      dataSheet.getCell(`B${summaryStartRow + 4}`).value = summary.totalEmissions;
    }
    
    // Add deviations sheet if any exist
    if (deviations.length > 0) {
      const deviationSheet = workbook.addWorksheet('Deviations');
      deviationSheet.columns = [
        { header: 'Date/Time', key: 'dateTime', width: 20 },
        { header: 'Type', key: 'type', width: 15 },
        { header: 'Description', key: 'description', width: 40 },
        { header: 'Status', key: 'status', width: 10 },
      ];
      
      deviations.forEach(dev => {
        deviationSheet.addRow({
          dateTime: dev.dateTime?.toLocaleString(),
          type: dev.type,
          description: dev.description,
          status: dev.status,
        });
      });
    }
    
    // Auto-fit columns
    dataSheet.columns.forEach(column => {
      column.width = Math.max(column.width || 10, 15);
    });
    
    // Generate file
    const buffer = await workbook.xlsx.writeBuffer();
    const fileName = `thermal-log-${projectId}-${logId}-${Date.now()}.xlsx`;
    
    // Upload to Firebase Storage
    const bucket = storage.bucket();
    const file = bucket.file(`reports/${projectId}/${fileName}`);
    
    await file.save(buffer, {
      metadata: {
        contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        metadata: {
          generatedBy: session.uid,
          generatedAt: new Date().toISOString(),
        },
      },
    });
    
    // Get download URL
    const [url] = await file.getSignedUrl({
      action: 'read',
      expires: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days
    });
    
    return {
      url,
      fileName,
      bytes: buffer.byteLength,
    };
  } catch (error) {
    console.error('Error generating Excel report:', error);
    throw new Error('Failed to generate Excel report');
  }
}

function getHeadersForLogType(logType: string): string[] {
  const baseHeaders = ['Date', 'Time', 'Hour', 'Exhaust Temp (°F)', 'Flow (scfh)'];
  
  switch (logType) {
    case 'H2S':
      return [...baseHeaders, 'H2S (ppm)', 'Operator', 'Notes'];
    case 'Benzene':
      return [...baseHeaders, 'Benzene (ppm)', 'Operator', 'Notes'];
    case 'Combined':
      return [...baseHeaders, 'H2S (ppm)', 'Benzene (ppm)', 'Operator', 'Notes'];
    default:
      return [...baseHeaders, 'Operator', 'Notes'];
  }
}

function formatEntryRow(entry: LogEntry, logType: string): any[] {
  const timestamp = entry.timestamp.toDate();
  const baseRow = [
    timestamp.toLocaleDateString(),
    timestamp.toLocaleTimeString(),
    entry.hour,
    entry.exhaustTemp,
    entry.flow,
  ];
  
  switch (logType) {
    case 'H2S':
      return [...baseRow, entry.h2sPpm || 0, entry.operatorId, entry.notes || ''];
    case 'Benzene':
      return [...baseRow, entry.benzenePpm || 0, entry.operatorId, entry.notes || ''];
    case 'Combined':
      return [...baseRow, entry.h2sPpm || 0, entry.benzenePpm || 0, entry.operatorId, entry.notes || ''];
    default:
      return [...baseRow, entry.operatorId, entry.notes || ''];
  }
}

function calculateSummary(entries: LogEntry[]) {
  if (entries.length === 0) {
    return {
      totalHours: 0,
      avgExhaustTemp: 0,
      avgFlow: 0,
    };
  }
  
  const totalExhaustTemp = entries.reduce((sum, e) => sum + e.exhaustTemp, 0);
  const totalFlow = entries.reduce((sum, e) => sum + e.flow, 0);
  const maxH2s = Math.max(...entries.map(e => e.h2sPpm || 0));
  const maxBenzene = Math.max(...entries.map(e => e.benzenePpm || 0));
  
  return {
    totalHours: entries.length,
    avgExhaustTemp: Math.round(totalExhaustTemp / entries.length),
    avgFlow: Math.round(totalFlow / entries.length),
    totalEmissions: undefined, // Calculate if needed
    maxH2s: maxH2s > 0 ? maxH2s : undefined,
    maxBenzene: maxBenzene > 0 ? maxBenzene : undefined,
  };
}