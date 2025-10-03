import { NextRequest, NextResponse } from 'next/server';
import * as XLSX from 'xlsx';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const path = searchParams.get('path');

    if (!path) {
      return NextResponse.json({ error: 'Path parameter is required' }, { status: 400 });
    }

    console.log('Generating mock Excel file for path:', path);

    // Create a mock Excel workbook with thermal log data
    const workbook = XLSX.utils.book_new();
    
    // Create worksheet data that matches thermal log structure
    const worksheetData = [
      // Headers row (row 11)
      ['', '', '', '', '', '', '', '', '', '', '', '', ''],
      // Main headers row (row 12) 
      ['', 'Time', 'Temp (°F)', 'Pressure (psi)', 'Flow Rate', 'H₂S (ppm)', 'LEL (%)', 'O₂ (%)', 'Benzene (ppm)', 'Comments', 'Operator', 'Status', ''],
      // Data rows (13-28)
      ['', '00:00', '72.5', '150.2', '250.0', '0', '0', '20.9', '0', 'Initial reading', 'J.Smith', 'Active', ''],
      ['', '01:00', '73.1', '151.8', '248.5', '0', '0', '20.8', '0', 'Normal operation', 'J.Smith', 'Active', ''],
      ['', '02:00', '73.8', '149.6', '252.1', '0', '0', '20.9', '0', 'Flow adjusted', 'J.Smith', 'Active', ''],
      ['', '03:00', '74.2', '150.9', '251.3', '2', '0', '20.8', '0', 'Minor H₂S detected', 'J.Smith', 'Monitor', ''],
      ['', '04:00', '73.9', '152.1', '249.8', '1', '0', '20.9', '0', 'H₂S reducing', 'J.Smith', 'Active', ''],
      ['', '05:00', '73.5', '150.5', '250.7', '0', '0', '20.9', '0', 'Normal operation', 'M.Johnson', 'Active', ''],
      ['', '06:00', '74.1', '151.2', '248.9', '0', '0', '20.8', '0', 'Shift change', 'M.Johnson', 'Active', ''],
      ['', '07:00', '74.8', '149.8', '251.5', '0', '0', '20.9', '0', 'Temperature rising', 'M.Johnson', 'Monitor', ''],
      ['', '08:00', '75.2', '150.4', '250.2', '0', '0', '20.8', '0', 'Within limits', 'M.Johnson', 'Active', ''],
      ['', '09:00', '74.9', '151.6', '249.1', '0', '0', '20.9', '0', 'Normal operation', 'M.Johnson', 'Active', ''],
      ['', '10:00', '74.3', '150.8', '251.8', '0', '0', '20.9', '0', 'Equipment check', 'M.Johnson', 'Active', ''],
      ['', '11:00', '73.7', '149.9', '250.4', '0', '0', '20.8', '0', 'All systems normal', 'M.Johnson', 'Active', ''],
      ['', '12:00', '74.0', '151.1', '248.7', '0', '1.2', '20.9', '0', 'LEL spike noted', 'R.Davis', 'Monitor', ''],
      ['', '13:00', '74.5', '150.3', '250.9', '0', '0.8', '20.8', '0', 'LEL decreasing', 'R.Davis', 'Active', ''],
      ['', '14:00', '74.1', '151.7', '249.6', '0', '0', '20.9', '0', 'Back to normal', 'R.Davis', 'Active', ''],
      ['', '15:00', '73.8', '150.6', '251.2', '0', '0', '20.9', '0', 'End of shift', 'R.Davis', 'Active', ''],
    ];

    // Apply dynamic substitutions based on template path
    if (path.includes('pentane')) {
      // Convert methane references to pentane
      worksheetData[1][2] = 'Pentane Temp (°F)';
      worksheetData[1][4] = 'C5H12 Flow Rate';
    }

    if (path.includes('h2s')) {
      // Increase H₂S values for H₂S-specific templates
      for (let i = 2; i < worksheetData.length; i++) {
        if (Math.random() > 0.7) { // 30% chance of H₂S detection
          worksheetData[i][5] = (Math.random() * 10 + 1).toFixed(1);
        }
      }
    }

    if (path.includes('benzene')) {
      // Add benzene detections
      for (let i = 2; i < worksheetData.length; i++) {
        if (Math.random() > 0.8) { // 20% chance of benzene detection
          worksheetData[i][8] = (Math.random() * 2 + 0.5).toFixed(1);
        }
      }
    }

    if (path.includes('lel')) {
      // Add LEL readings
      for (let i = 2; i < worksheetData.length; i++) {
        if (Math.random() > 0.85) { // 15% chance of LEL detection
          worksheetData[i][6] = (Math.random() * 5 + 0.5).toFixed(1);
        }
      }
    }

    if (path.includes('12hr') || path.includes('12-hour')) {
      // Convert to 12-hour format
      for (let i = 2; i < worksheetData.length; i++) {
        const time = worksheetData[i][1];
        if (typeof time === 'string' && time.includes(':')) {
          const [hours] = time.split(':');
          const hour24 = parseInt(hours);
          const hour12 = hour24 === 0 ? 12 : hour24 > 12 ? hour24 - 12 : hour24;
          const period = hour24 >= 12 ? 'PM' : 'AM';
          worksheetData[i][1] = `${hour12}:00 ${period}`;
        }
      }
    }

    // Create worksheet
    const worksheet = XLSX.utils.aoa_to_sheet(worksheetData);

    // Set column widths
    worksheet['!cols'] = [
      { wch: 5 },   // A
      { wch: 8 },   // B - Time
      { wch: 12 },  // C - Temp
      { wch: 15 },  // D - Pressure
      { wch: 12 },  // E - Flow Rate
      { wch: 10 },  // F - H₂S
      { wch: 8 },   // G - LEL
      { wch: 8 },   // H - O₂
      { wch: 12 },  // I - Benzene
      { wch: 20 },  // J - Comments
      { wch: 12 },  // K - Operator
      { wch: 10 },  // L - Status
      { wch: 5 },   // M
    ];

    // Set row heights
    worksheet['!rows'] = new Array(worksheetData.length).fill({ hpt: 20 });

    // Apply basic styling to headers
    const headerStyle = {
      font: { bold: true, color: { rgb: "FFFFFF" } },
      fill: { fgColor: { rgb: "4472C4" } },
      alignment: { horizontal: "center" }
    };

    // Apply header styles to row 12 (index 1)
    for (let col = 1; col <= 12; col++) {
      const cellRef = XLSX.utils.encode_cell({ r: 1, c: col });
      if (!worksheet[cellRef]) worksheet[cellRef] = { v: '', t: 's' };
      worksheet[cellRef].s = headerStyle;
    }

    // Set the worksheet range to B12:N28 (operation range)
    worksheet['!ref'] = 'B12:N28';

    // Add worksheet to workbook
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Thermal Log');

    // Generate Excel file buffer
    const excelBuffer = XLSX.write(workbook, { 
      type: 'buffer', 
      bookType: 'xlsx',
      cellStyles: true 
    });

    console.log('Generated mock Excel file, size:', excelBuffer.length, 'bytes');

    // Return the Excel file
    return new NextResponse(excelBuffer, {
      status: 200,
      headers: {
        'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'Content-Length': excelBuffer.length.toString(),
        'Cache-Control': 'public, max-age=300', // Cache for 5 minutes in dev
      },
    });
  } catch (error) {
    console.error('Error generating mock Excel file:', error);
    
    return NextResponse.json(
      { error: 'Failed to generate Excel file' },
      { status: 500 }
    );
  }
}