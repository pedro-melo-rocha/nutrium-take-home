interface Props {
  page: number
  totalPages: number
  onChange: (page: number) => void
}

/** Windowed numeric pager: ‹ 1 … 4 5 6 … 12 › */
export function Pagination({ page, totalPages, onChange }: Props) {
  if (totalPages <= 1) return null

  const pages = pageWindow(page, totalPages)

  return (
    <nav
      className="flex items-center justify-center gap-1"
      aria-label="Pagination"
    >
      <PageButton
        label="‹"
        ariaLabel="Previous page"
        disabled={page <= 1}
        onClick={() => onChange(page - 1)}
      />
      {pages.map((p, i) =>
        p === '…' ? (
          <span key={`gap-${i}`} className="px-2 text-slate-400">
            …
          </span>
        ) : (
          <PageButton
            key={p}
            label={String(p)}
            active={p === page}
            onClick={() => onChange(p)}
          />
        ),
      )}
      <PageButton
        label="›"
        ariaLabel="Next page"
        disabled={page >= totalPages}
        onClick={() => onChange(page + 1)}
      />
    </nav>
  )
}

interface PageButtonProps {
  label: string
  ariaLabel?: string
  active?: boolean
  disabled?: boolean
  onClick: () => void
}

function PageButton({
  label,
  ariaLabel,
  active,
  disabled,
  onClick,
}: PageButtonProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      aria-label={ariaLabel}
      aria-current={active ? 'page' : undefined}
      className={`grid size-9 place-items-center rounded-md text-sm font-medium transition disabled:cursor-not-allowed disabled:opacity-40 ${
        active
          ? 'bg-brand-500 text-white'
          : 'text-slate-600 hover:bg-slate-100'
      }`}
    >
      {label}
    </button>
  )
}

function pageWindow(current: number, total: number): (number | '…')[] {
  const span = 1
  const out: (number | '…')[] = []
  let last = 0
  for (let p = 1; p <= total; p++) {
    const edge = p === 1 || p === total
    const near = p >= current - span && p <= current + span
    if (edge || near) {
      if (last && p - last > 1) out.push('…')
      out.push(p)
      last = p
    }
  }
  return out
}
