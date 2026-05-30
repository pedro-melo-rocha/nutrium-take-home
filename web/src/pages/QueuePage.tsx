import { useState, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { Link, useParams } from 'react-router-dom'
import { useQueue } from '../api/appointments'
import { AnswerModal } from '../components/queue/AnswerModal'
import { RequestCard } from '../components/queue/RequestCard'
import { LanguageToggle } from '../components/LanguageToggle'
import { Logo } from '../components/Logo'
import { Spinner } from '../components/Spinner'
import { ChevronLeftIcon, ChevronRightIcon, HistoryIcon } from '../components/icons'
import { ApiError } from '../lib/api'
import type { AppointmentRequest } from '../lib/types'

const PAGE_SIZE = 3

type View = 'pending' | 'history'

export default function QueuePage() {
  const { t } = useTranslation()
  const { id = '' } = useParams()
  const [view, setView] = useState<View>('pending')
  const [page, setPage] = useState(0)
  const [answering, setAnswering] = useState<AppointmentRequest | null>(null)

  const isHistory = view === 'history'
  const pending = useQueue(id, 'pending')
  const accepted = useQueue(id, 'accepted', isHistory)
  const rejected = useQueue(id, 'rejected', isHistory)

  const nutritionistName = pending.data?.nutritionist.name

  const isLoading = isHistory
    ? accepted.isLoading || rejected.isLoading
    : pending.isLoading
  const isFetching = isHistory
    ? accepted.isFetching || rejected.isFetching
    : pending.isFetching
  const error = isHistory
    ? (accepted.error ?? rejected.error)
    : pending.error
  const isError = isHistory
    ? accepted.isError || rejected.isError
    : pending.isError

  const items: AppointmentRequest[] = isHistory
    ? [...(accepted.data?.results ?? []), ...(rejected.data?.results ?? [])].sort(
        (a, b) => b.created_at.localeCompare(a.created_at),
      )
    : (pending.data?.results ?? [])

  const totalPages = Math.max(1, Math.ceil(items.length / PAGE_SIZE))
  const safePage = Math.min(page, totalPages - 1)
  const visible = items.slice(safePage * PAGE_SIZE, safePage * PAGE_SIZE + PAGE_SIZE)

  function switchView(next: View) {
    setView(next)
    setPage(0)
  }

  return (
    <div className="min-h-screen bg-slate-50">
      <header className="bg-white shadow-sm">
        <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-4">
          <Link to="/">
            <Logo className="text-brand-600" />
          </Link>
          <div className="flex items-center gap-4 text-sm">
            {nutritionistName && (
              <span className="hidden text-slate-500 sm:inline">
                {t('queue.signedInAs', { name: nutritionistName })}
              </span>
            )}
            <Link
              to="/professional"
              className="font-medium text-brand-600 transition hover:text-brand-700"
            >
              {t('queue.switchAccount')}
            </Link>
            <LanguageToggle />
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-5xl px-4 py-8">
        <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
            <div>
              <h1 className="text-2xl font-semibold text-slate-800">
                {isHistory ? t('queue.historyTitle') : t('queue.pendingTitle')}
              </h1>
              <p className="mt-1 text-sm text-slate-500">
                {isHistory
                  ? t('queue.historySubtitle')
                  : t('queue.pendingSubtitle')}
              </p>
            </div>

            <div className="flex items-center gap-2">
              <IconButton
                ariaLabel={t('queue.prevPage')}
                disabled={safePage <= 0}
                onClick={() => setPage((p) => Math.max(0, p - 1))}
              >
                <ChevronLeftIcon className="size-5" />
              </IconButton>
              <IconButton
                ariaLabel={t('queue.nextPage')}
                disabled={safePage >= totalPages - 1}
                onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
              >
                <ChevronRightIcon className="size-5" />
              </IconButton>
              <IconButton
                ariaLabel={isHistory ? t('queue.viewPending') : t('queue.viewHistory')}
                active={isHistory}
                onClick={() => switchView(isHistory ? 'pending' : 'history')}
              >
                <HistoryIcon className="size-5" />
              </IconButton>
            </div>
          </div>

          {isLoading ? (
            <SkeletonGrid />
          ) : isError ? (
            <EmptyState
              title={t('queue.errorTitle')}
              body={error instanceof ApiError ? error.message : t('queue.errorBody')}
            />
          ) : visible.length > 0 ? (
            <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {visible.map((req) => (
                <RequestCard
                  key={req.id}
                  request={req}
                  onAnswer={() => setAnswering(req)}
                />
              ))}
            </div>
          ) : (
            <EmptyState
              title={t(
                isHistory ? 'queue.emptyHistoryTitle' : 'queue.emptyPendingTitle',
              )}
              body={t(
                isHistory ? 'queue.emptyHistoryBody' : 'queue.emptyPendingBody',
              )}
            />
          )}

          {isFetching && !isLoading && (
            <div className="mt-4 flex justify-center">
              <Spinner className="size-5 text-brand-500" />
            </div>
          )}
        </section>
      </main>

      {answering && (
        <AnswerModal
          request={answering}
          nutritionistId={id}
          onClose={() => setAnswering(null)}
        />
      )}
    </div>
  )
}

function IconButton({
  children,
  ariaLabel,
  active,
  disabled,
  onClick,
}: {
  children: ReactNode
  ariaLabel: string
  active?: boolean
  disabled?: boolean
  onClick: () => void
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      aria-label={ariaLabel}
      aria-pressed={active}
      className={`grid size-9 place-items-center rounded-lg border transition disabled:cursor-not-allowed disabled:opacity-40 ${
        active
          ? 'border-brand-500 bg-brand-50 text-brand-600'
          : 'border-slate-200 text-slate-500 hover:bg-slate-50 hover:text-slate-700'
      }`}
    >
      {children}
    </button>
  )
}

function SkeletonGrid() {
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {Array.from({ length: 3 }).map((_, i) => (
        <div
          key={i}
          className="animate-pulse rounded-2xl border border-slate-200 bg-white p-5"
        >
          <div className="flex items-center gap-3">
            <div className="size-12 shrink-0 rounded-full bg-slate-200" />
            <div className="flex-1 space-y-2">
              <div className="h-4 w-28 rounded bg-slate-200" />
              <div className="h-3 w-36 rounded bg-slate-100" />
            </div>
          </div>
          <div className="mt-4 space-y-2">
            <div className="h-3 w-32 rounded bg-slate-100" />
            <div className="h-3 w-20 rounded bg-slate-100" />
          </div>
          <div className="mt-4 h-5 w-24 rounded bg-slate-100" />
        </div>
      ))}
    </div>
  )
}

function EmptyState({ title, body }: { title: string; body: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-slate-300 py-16 text-center">
      <p className="text-base font-medium text-slate-700">{title}</p>
      <p className="mt-1 text-sm text-slate-500">{body}</p>
    </div>
  )
}
