interface LogoProps {
  className?: string
}

export function Logo({ className = '' }: LogoProps) {
  return (
    <span className={`inline-flex items-center gap-2 ${className}`}>
      <svg viewBox="0 0 24 24" className="size-6" aria-hidden="true">
        <path
          d="M5 19c0-7 5-12 14-13 0 9-5 14-12 14-1 0-2 0-2-1Z"
          fill="currentColor"
          opacity="0.95"
        />
        <path
          d="M7 18c3-5 6-8 10-9"
          fill="none"
          stroke="white"
          strokeWidth="1.4"
          strokeLinecap="round"
        />
      </svg>
      <span className="text-xl font-semibold tracking-tight">nutri</span>
    </span>
  )
}
