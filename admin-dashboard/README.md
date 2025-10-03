# Admin Dashboard

> Next.js-based administrative portal for the Thermal Compliance App

## Features

- 📊 **Real-time monitoring** - Live view of all field operations
- 🎨 **Template builder** - Visual form designer for data collection
- 📈 **Excel exports** - Automated regulatory report generation
- 👥 **User management** - Role-based access control
- 🔍 **Audit logs** - Complete data modification history

## Tech Stack

- **Next.js 15** - React framework with App Router
- **React 19** - Latest React with Server Components
- **TypeScript** - Type-safe development
- **Tailwind CSS** - Utility-first styling
- **Radix UI** - Accessible component primitives
- **ExcelJS** - Excel file generation
- **Firebase Admin SDK** - Backend integration

## Getting Started

### **Development**
```bash
npm install
npm run dev
```

Visit http://localhost:3000

### **Build**
```bash
npm run build
npm run start
```

### **Environment Variables**
Create `.env.local`:
```
NEXT_PUBLIC_FIREBASE_API_KEY=your_key
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your_project
FIREBASE_SERVICE_ACCOUNT_KEY=your_service_account_json
```

## Project Structure

```
admin-dashboard/
├── src/
│   ├── app/              # Next.js App Router
│   ├── components/       # React components
│   ├── lib/             # Utilities and helpers
│   └── styles/          # Global styles
├── public/              # Static assets
├── package.json
└── next.config.js
```

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
