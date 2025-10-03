"use client"

import * as React from "react"
import { cn } from "@/lib/utils"

interface AlertDialogProps {
  children: React.ReactNode
}

interface AlertDialogTriggerProps {
  children: React.ReactNode
  asChild?: boolean
}

interface AlertDialogContentProps {
  children: React.ReactNode
  className?: string
}

interface AlertDialogHeaderProps {
  children: React.ReactNode
  className?: string
}

interface AlertDialogTitleProps {
  children: React.ReactNode
  className?: string
}

interface AlertDialogDescriptionProps {
  children: React.ReactNode
  className?: string
}

interface AlertDialogFooterProps {
  children: React.ReactNode
  className?: string
}

interface AlertDialogActionProps {
  children: React.ReactNode
  className?: string
  onClick?: () => void
}

interface AlertDialogCancelProps {
  children: React.ReactNode
  className?: string
  onClick?: () => void
}

const AlertDialog = ({ children }: AlertDialogProps) => {
  return <div data-testid="alert-dialog">{children}</div>
}

const AlertDialogTrigger = ({ children }: AlertDialogTriggerProps) => {
  return <>{children}</>
}

const AlertDialogContent = ({ children, className }: AlertDialogContentProps) => {
  return (
    <div
      className={cn("fixed inset-0 z-50 bg-background/80 backdrop-blur-sm", className)}
      role="dialog"
      aria-modal="true"
    >
      {children}
    </div>
  )
}

const AlertDialogHeader = ({ children, className }: AlertDialogHeaderProps) => {
  return (
    <div className={cn("flex flex-col space-y-2 text-center sm:text-left", className)}>
      {children}
    </div>
  )
}

const AlertDialogTitle = ({ children, className }: AlertDialogTitleProps) => {
  return (
    <h2 className={cn("text-lg font-semibold", className)}>
      {children}
    </h2>
  )
}

const AlertDialogDescription = ({ children, className }: AlertDialogDescriptionProps) => {
  return (
    <p className={cn("text-sm text-muted-foreground", className)}>
      {children}
    </p>
  )
}

const AlertDialogFooter = ({ children, className }: AlertDialogFooterProps) => {
  return (
    <div className={cn("flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2", className)}>
      {children}
    </div>
  )
}

const AlertDialogAction = ({ children, className, onClick }: AlertDialogActionProps) => {
  return (
    <button className={cn("btn btn-destructive", className)} onClick={onClick}>
      {children}
    </button>
  )
}

const AlertDialogCancel = ({ children, className, onClick }: AlertDialogCancelProps) => {
  return (
    <button className={cn("btn btn-outline", className)} onClick={onClick}>
      {children}
    </button>
  )
}

export {
  AlertDialog,
  AlertDialogTrigger,
  AlertDialogContent,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogAction,
  AlertDialogCancel,
}
