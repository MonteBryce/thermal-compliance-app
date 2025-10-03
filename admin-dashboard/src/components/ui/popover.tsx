"use client"

import * as React from "react"
import { cn } from "@/lib/utils"

interface PopoverProps {
  children: React.ReactNode
}

interface PopoverTriggerProps {
  children: React.ReactNode
  asChild?: boolean
}

interface PopoverContentProps {
  children: React.ReactNode
  className?: string
  align?: 'start' | 'center' | 'end'
  side?: 'top' | 'right' | 'bottom' | 'left'
}

const Popover = ({ children }: PopoverProps) => {
  return <div className="relative">{children}</div>
}

const PopoverTrigger = ({ children }: PopoverTriggerProps) => {
  return <>{children}</>
}

const PopoverContent = ({ children, className, align = 'center', side = 'bottom' }: PopoverContentProps) => {
  return (
    <div
      className={cn(
        "z-50 w-72 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none",
        className
      )}
      role="dialog"
    >
      {children}
    </div>
  )
}

export { Popover, PopoverTrigger, PopoverContent }
