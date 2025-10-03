import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import { AuthProvider } from '@/lib/contexts/AuthContext'
import { ServiceWorkerProvider } from '@/components/providers/ServiceWorkerProvider'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Thermal Log Admin Dashboard',
  description: 'Manage thermal log templates, projects, and operator assignments',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.className} bg-[#111111] text-white antialiased`}>
        <ServiceWorkerProvider>
          <AuthProvider>
            {children}
          </AuthProvider>
        </ServiceWorkerProvider>
      </body>
    </html>
  )
}