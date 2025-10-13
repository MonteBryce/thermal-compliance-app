# Project Summary Screen - Wireframe

```
┌─────────────────────────────────────────────────────────────┐
│ ← [Back]          Project Summary              🔄 [Refresh] │ AppBar
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Project Name                            [Status Badge]│  │ _buildProjectHeader()
│  │ (displayJob.projectName)                 (In Progress)│  │ Row widget
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Operational Parameters                                │  │ _buildOperationalParameters()
│  │                                                        │  │ Container (0xFF152042)
│  │  📋 Work Order #:                    WO-12345         │  │
│  │  🏢 Unit #:                          Unit-A           │  │
│  │  📦 Tank Type:                       thermal          │  │
│  │  🥤 Product:                         Crude Oil        │  │
│  │  ⚡ Facility Target:                 95%              │  │ Each: _buildParameterRow()
│  │  🌡️ Operating Temp:                  350°F            │  │
│  │  🧪 Benzene Target:                  <1 ppm           │  │
│  │  ⚠️ H₂S Amp Required:                Yes              │  │
│  │                                                        │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ ℹ️ Selected Date: Jan 15, 2025      12/24 hours      │  │ Date info banner
│  └───────────────────────────────────────────────────────┘  │ (if date selected)
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ [Date Selector Widget]                                │  │ DateSelectorWidget
│  │ Calendar/date picker component                        │  │ (imported component)
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ Daily Progress (Today)                          🔄    │  │ _buildDailyProgress()
│  │                                                        │  │ Container (0xFF152042)
│  │  Hours Logged              Last entry: 30 min ago    │  │
│  │                                                        │  │
│  │  ████████████░░░░░░░░░░░░░░                          │  │ Progress bar (Stack)
│  │                                                        │  │ AnimatedContainer
│  │  18/24 hours                                    75%   │  │
│  │                                                        │  │
│  │  ✅ [Success banner if 24/24 complete]               │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ ⚠️ 6 hourly entries still required for today          │  │ _buildWarningBanner()
│  │                                                        │  │ AnimatedContainer
│  │  ▼ Show missing hours                                │  │ (if missing hours > 0)
│  │     [01:00] [02:00] [03:00] [15:00] [16:00] [17:00]  │  │ ExpansionTile
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  📝  Start Logging Hourly Data                       │  │
│  │      Select a date above first, or use today         │  │ _buildActionButtonWithText()
│  └───────────────────────────────────────────────────────┘  │ Material + InkWell
│                                                               │ (color: 0xFF2563EB)
│  ┌───────────────────────────────────────────────────────┐  │
│  │  📊  Enter System Metrics                            │  │ _buildActionButtonWithText()
│  │      Update system parameters and readings           │  │ (color: Colors.green)
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  🕒  Review All Entries                              │  │ _buildActionButtonWithText()
│  │      View and edit previous entries                  │  │ (color: Colors.purple)
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  📷  Scan Paper Log                                   │  │ _buildActionButtonWithText()
│  │      Use OCR to extract data from photos             │  │ (color: Colors.orange)
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  ─────────────────────────────────────────────────────────  │ Divider
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  ✅  Job Completed                                    │  │ _buildActionButtonWithText()
│  │      Enter final readings and complete project       │  │ (color: 0xFF10B981)
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
└─────────────────────────────────────────────────────────────┘

```

## Container Breakdown

### Main Structure
- **Scaffold** (backgroundColor: `0xFF0B132B` - dark navy)
  - **AppBar** (backgroundColor: `0xFF0B132B`)
  - **RefreshIndicator** (wraps body)
    - **SingleChildScrollView**
      - **Column** (padding: 24)

### Individual Containers

1. **Project Header** - `_buildProjectHeader()` (line 647)
   - Row with project name and status badge
   - Status badge: Container with rounded corners

2. **Operational Parameters** - `_buildOperationalParameters()` (line 757)
   - Container (backgroundColor: `0xFF152042` - lighter navy)
   - borderRadius: 16
   - padding: 24
   - Contains 8 parameter rows

3. **Date Info Banner** (line 701-741)
   - Container (backgroundColor: `0xFF2563EB` with 10% opacity)
   - Border: blue with 30% opacity
   - Only shows when date is selected

4. **Date Selector** - `DateSelectorWidget` (line 742)
   - Imported component

5. **Daily Progress** - `_buildDailyProgress()` (line 850)
   - Container (backgroundColor: `0xFF152042`)
   - borderRadius: 16
   - padding: 24
   - Contains: progress bar (Stack with AnimatedContainer)

6. **Warning Banner** - `_buildWarningBanner()` (line 992)
   - AnimatedContainer (changes color based on missing hours)
   - Red tint if >12 hours missing, orange if ≤12
   - borderRadius: 12
   - Contains ExpansionTile for missing hour chips

7. **Action Buttons** - `_buildActionButtonWithText()` (line 1150)
   - Material (backgroundColor: `0xFF152042`)
   - InkWell for tap effects
   - borderRadius: 16
   - padding: 24
   - Icon container with color.withOpacity(0.1) background

## Color Palette
- **Background**: `0xFF0B132B` (dark navy)
- **Cards/Containers**: `0xFF152042` (lighter navy)
- **Primary Blue**: `0xFF2563EB`
- **Success Green**: `0xFF10B981`
- **Warning Orange**: `Colors.orange`
- **Error Red**: `Colors.red`
- **Purple**: `Colors.purple`
