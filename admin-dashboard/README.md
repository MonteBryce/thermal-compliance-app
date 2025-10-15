# Admin Dashboard

# Architecture Overview
The Admin Dashboard is a Next.js-based portal for managing, monitoring, and exporting compliance data. It follows a modular monolith style, leveraging React Server Components, Firebase Admin SDK, and ExcelJS for regulatory reporting.

## High-Level Diagram
*(Embed a diagram here, e.g., Mermaid, ASCII, or SVG. If you have an SVG, use:)*  
`![Admin Dashboard Architecture](../docs/admin-dashboard-architecture.svg)`

## Code Map / Components
- **src/app/**: Next.js App Router, layouts, pages (`login/`, `admin/`, `sandbox/`, etc.)
- **src/components/**: Modular React components
  - `auth/`: AuthGuard, PermissionGuard
  - `charts/`: UsageMetricsChart, PerformanceChart, ExportStatsChart
  - `excel/`: ExcelPreview
  - `logbuilder/`: SmartFieldBuilder, ComplianceIntelligence, ValidationWidget, etc.
  - `template/`: MetricDesignerPanel, StructureValidationPanel, TemplateGridPreview
  - `ui/`: UI primitives (Button, Card, Table, etc.)
  - `providers/`: ServiceWorkerProvider
  - `lazy/`: Dynamic imports, lazy wrappers
- **public/**: Static assets
- **package.json**: Project manifest
- **next.config.js**: Next.js configuration

## Technology Stack
- **Languages**: TypeScript, JavaScript
- **Frameworks**: Next.js 15, React 19, Tailwind CSS, Radix UI
- **Backend/Infra**: Firebase Admin SDK, ExcelJS
- **Testing**: Jest, React Testing Library

## Design Decisions
- **Server Components**: For performance and scalability
- **Role-based Access**: AuthGuard, PermissionGuard for RBAC
- **ExcelJS**: Automated, customizable Excel exports
- **Modular UI**: Reusable primitives and feature modules
- **Firebase Admin SDK**: Secure backend integration

## Getting Started for Developers
1. **Install dependencies**  
	```bash
	npm install
	```
2. **Run locally**  
	```bash
	npm run dev
	```
	Visit [http://localhost:3000](http://localhost:3000)
3. **Build for production**  
	```bash
	npm run build
	npm run start
	```
4. **Environment setup**  
	- Create `.env.local` with Firebase and service account keys

## Cross-Cutting Concerns
- **Testing**: Unit and integration tests in `src/` and `__tests__/`
- **Error Handling**: Centralized in components and API routes
- **Logging**: Audit logs, operation history
- **Security**: RBAC, JWT, secure environment variables
- **Performance**: Server Components, lazy loading, optimized queries

## References
- [Main App README](../README.md)
- [Architecture Diagrams](../docs/)
- [Next.js Docs](https://nextjs.org/docs)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [ExcelJS](https://github.com/exceljs/exceljs)

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint
- `npm run type-check` - Run TypeScript checks
- `npm test` - Run tests

## Key Features

### **Dashboard Overview**
- Active job count
- Compliance metrics
- Recent data entries
- Operator status

### **Template Builder**
- Drag-and-drop form designer
- Field type selection (text, number, date, etc.)
- Validation rules configuration
- Preview mode

### **Excel Export Engine**
- Template-based generation
- Multi-sheet support
- Formula calculations
- Conditional formatting

### **User Management**
- Create/edit users
- Assign roles (Operator, Supervisor, Manager, Admin)
- Job assignments
- Activity tracking

## Development Guidelines

- Use Server Components by default
- Add 'use client' only when needed
- Follow Next.js App Router conventions
- Keep components small and focused
- Use TypeScript strictly

## Deployment

Deploy to Firebase Hosting:
```bash
npm run build
firebase deploy --only hosting
```

## License

MIT - See root LICENSE file
