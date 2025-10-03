import { NextRequest, NextResponse } from 'next/server';
import XlsxPopulate from 'xlsx-populate';
import { z } from 'zod';
import path from 'path';
import fs from 'fs';

// Zod schema for request validation
const HourlyRowSchema = z.object({
  timeDisplay: z.string().trim(),
  vaporInletFpm: z.number().optional(),
  vaporInletBblHr: z.number().optional(),
  combustionAirFpm: z.number().optional(),
  exhaustTempF: z.number().optional(),
  vacuumInH2O: z.number().optional(),
  inletPpm: z.number().optional(),
  outletPpm: z.number().optional(),
  lelPercent: z.number().optional(),
  operator1Initials: z.string().trim().max(8).optional(),
  operator2Initials: z.string().trim().max(8).optional(),
  activityNote: z.string().trim().optional(),
  meters10Flag: z.boolean().optional(),
  inspectionTimestamp: z.string().trim().optional(),
});

const ExportRequestSchema = z.object({
  projectId: z.string().min(1, 'Project ID is required'),
  date: z.string().regex(/^\d{8}$/, 'Date must be in YYYYMMDD format'),
  rows: z.array(HourlyRowSchema).max(24, 'Maximum 24 hourly rows allowed'),
});

type HourlyRow = z.infer<typeof HourlyRowSchema>;
type ExportRequest = z.infer<typeof ExportRequestSchema>;

// Template file path
const TEMPLATE_PENTANE_HOURLY_PATH = path.join(process.cwd(), 'app', 'templates', 'TX_10-60_PENTANE_Hourly.xlsx');

/**
 * Helper function to write a column array to a named range
 * @param workbook - XlsxPopulate workbook instance
 * @param rangeName - Named range identifier
 * @param values - Array of values to write
 */
function writeCol(workbook: any, rangeName: string, values: any[]): void {
  try {
    const range = workbook.definedName(rangeName);
    if (!range) {
      console.warn(`Named range '${rangeName}' not found in template`);
      return;
    }

    // Convert to 2D array format for xlsx-populate
    const columnData = values.map(value => [value ?? ""]);
    
    // Write the column data to the named range
    range.value(columnData);
  } catch (error) {
    console.error(`Error writing to named range '${rangeName}':`, error);
    throw new Error(`Failed to write column '${rangeName}'`);
  }
}

/**
 * Processes and validates numeric values for Excel output
 * @param value - Input value
 * @param clampMin - Optional minimum value
 * @param clampMax - Optional maximum value
 * @returns Processed number or empty string
 */
function processNumericValue(value: number | undefined, clampMin?: number, clampMax?: number): number | string {
  if (value === undefined || value === null || isNaN(value)) {
    return "";
  }
  
  let processed = value;
  
  if (clampMin !== undefined && processed < clampMin) {
    processed = clampMin;
  }
  if (clampMax !== undefined && processed > clampMax) {
    processed = clampMax;
  }
  
  return processed;
}

/**
 * Processes string values for Excel output
 * @param value - Input string
 * @param maxLength - Maximum allowed length
 * @returns Processed string
 */
function processStringValue(value: string | undefined, maxLength?: number): string {
  if (!value) return "";
  
  let processed = value.toString().trim();
  
  if (maxLength && processed.length > maxLength) {
    processed = processed.substring(0, maxLength);
  }
  
  return processed;
}

export async function POST(request: NextRequest) {
  const startTime = Date.now();
  const errorId = `export-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

  try {
    // Parse and validate request body
    const body = await request.json();
    const validationResult = ExportRequestSchema.safeParse(body);

    if (!validationResult.success) {
      return NextResponse.json(
        { 
          error: 'Validation failed', 
          details: validationResult.error.flatten().fieldErrors 
        },
        { status: 400 }
      );
    }

    const { projectId, date, rows }: ExportRequest = validationResult.data;

    // Check if template file exists
    if (!fs.existsSync(TEMPLATE_PENTANE_HOURLY_PATH)) {
      console.error(`Template file not found: ${TEMPLATE_PENTANE_HOURLY_PATH}`);
      return NextResponse.json(
        { 
          errorId,
          error: 'Template file not available' 
        },
        { status: 500 }
      );
    }

    // Load the Excel template
    const workbook = await XlsxPopulate.fromFileAsync(TEMPLATE_PENTANE_HOURLY_PATH);

    // Process and map data to named ranges
    const timeData = rows.map(row => processStringValue(row.timeDisplay));
    const vaporInletFpmData = rows.map(row => processNumericValue(row.vaporInletFpm));
    const vaporInletBblHrData = rows.map(row => processNumericValue(row.vaporInletBblHr));
    const combustionAirFpmData = rows.map(row => processNumericValue(row.combustionAirFpm));
    const exhaustTempData = rows.map(row => processNumericValue(row.exhaustTempF));
    const vacuumData = rows.map(row => processNumericValue(row.vacuumInH2O));
    const inletPpmData = rows.map(row => processNumericValue(row.inletPpm));
    const outletPpmData = rows.map(row => processNumericValue(row.outletPpm));
    const lelData = rows.map(row => processNumericValue(row.lelPercent, 0, 100)); // Clamp LEL to 0-100%
    const operator1Data = rows.map(row => processStringValue(row.operator1Initials, 8));
    const operator2Data = rows.map(row => processStringValue(row.operator2Initials, 8));
    const notesData = rows.map(row => processStringValue(row.activityNote));
    const meters10Data = rows.map(row => row.meters10Flag ? "Yes" : "");
    const inspectionTimeData = rows.map(row => processStringValue(row.inspectionTimestamp));

    // Write data to named ranges
    writeCol(workbook, 'Hourly_Time', timeData);
    writeCol(workbook, 'Hourly_VaporInletFPM', vaporInletFpmData);
    writeCol(workbook, 'Hourly_VaporInletBBLHR', vaporInletBblHrData);
    writeCol(workbook, 'Hourly_CombustionAirFPM', combustionAirFpmData);
    writeCol(workbook, 'Hourly_ExhaustF', exhaustTempData);
    writeCol(workbook, 'Hourly_VacuumH2O', vacuumData);
    writeCol(workbook, 'Hourly_InletPPM', inletPpmData);
    writeCol(workbook, 'Hourly_OutletPPM', outletPpmData);
    writeCol(workbook, 'Hourly_LEL', lelData);
    writeCol(workbook, 'Hourly_Op1', operator1Data);
    writeCol(workbook, 'Hourly_Op2', operator2Data);
    writeCol(workbook, 'Hourly_Notes', notesData);
    writeCol(workbook, 'Hourly_Meters10LEL', meters10Data);
    writeCol(workbook, 'Hourly_InspectionTime', inspectionTimeData);

    // Generate the Excel file buffer
    const excelBuffer = await workbook.outputAsync();

    // Generate filename
    const filename = `${projectId}_${date}_pentane_hourly.xlsx`;

    // Log successful processing
    const processingTime = Date.now() - startTime;
    console.log(`Successfully exported ${rows.length} hourly rows for ${projectId}/${date} in ${processingTime}ms`);

    // Return the Excel file with proper headers
    return new NextResponse(excelBuffer, {
      status: 200,
      headers: {
        'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'Content-Disposition': `attachment; filename="${filename}"`,
        'Content-Length': excelBuffer.length.toString(),
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
      },
    });

  } catch (error) {
    const processingTime = Date.now() - startTime;
    console.error(`Export failed [${errorId}] after ${processingTime}ms:`, error);

    if (error instanceof SyntaxError) {
      return NextResponse.json(
        { error: 'Invalid JSON in request body' },
        { status: 400 }
      );
    }

    return NextResponse.json(
      { 
        errorId,
        error: 'Internal server error during export',
        message: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 500 }
    );
  }
}