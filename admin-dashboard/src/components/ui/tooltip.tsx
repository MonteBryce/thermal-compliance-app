"use client"

import * as React from "react"
import { cn } from "@/lib/utils"

interface TooltipProviderProps {
  children: React.ReactNode
}

interface TooltipProps {
  children: React.ReactNode
}

interface TooltipTriggerProps {
  children: React.ReactNode
  asChild?: boolean
}

interface TooltipContentProps {
  children: React.ReactNode
  className?: string
  side?: 'top' | 'right' | 'bottom' | 'left'
}

const TooltipProvider = ({ children }: TooltipProviderProps) => {
  return <>{children}</>
}

const Tooltip = ({ children }: TooltipProps) => {
  return <div className="relative inline-block">{children}</div>
}

const TooltipTrigger = ({ children }: TooltipTriggerProps) => {
  return <>{children}</>
}

const TooltipContent = ({ children, className, side = 'top' }: TooltipContentProps) => {
  return (
    <div
      className={cn(
        "z-50 overflow-hidden rounded-md bg-primary px-3 py-1.5 text-xs text-primary-foreground animate-in fade-in-0 zoom-in-95",
        className
      )}
      role="tooltip"
    >
      {children}
    </div>
  )
}

export { Tooltip, TooltipTrigger, TooltipContent, TooltipProvider }
