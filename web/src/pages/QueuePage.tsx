import { useState } from 'react'
import { useTranslation } from 'react-i18next'
import { Link, useParams } from 'react-router-dom'
import { useDecision, useQueue } from '../api/appointments'
import { LanguageToggle } from '../components/LanguageToggle'
import { Logo } from '../components/Logo'
import { Spinner } from '../components/Spinner'
import { RequestCard } from '../components/queue/RequestCard'
import { ApiError } from '../lib/api'
import type { AppointmentStatus } from '../lib/types'

const TAB_VALUES: AppointmentStatus[] = ['pending', 'accepted', 'rejected']

export default function QueuePage() {
  const { t } = useTranslation()
  const { id = '' } = useParams()
  const [status, setStatus] = useState<AppointmentStatus>('pending')

  const queue = useQueue(id, status)
  const decision = useDecision(id)

  const nutritionistName = queue.data?.nutritionist.name
  const results = queue.data?.results ?? []

  function decideFor(requestId: number, choice: 'accept' | 'reject') {
    decision.mutate({ requestId, decision: choice })
  }

  return (
    <div className="min-h-screen">
      <header className="bg-white shadow-sm">
        <div className="mx-auto flex max-w-4xl items-center justify-between px-4 py-4">
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

      <main className="mx-auto max-w-4xl px-4 py-8">
        <div className="mb-6">
          <h1 className="text-2xl font-semibold text-slate-800">
            {t('queue.title')}
          </h1>
          <p className="mt-1 text-sm text-slate-500">{t('queue.subtitle')}</p>
        </div>

        {/* Status tabs */}
        <div className="mb-6 inline-flex rounded-lg border border-slate-200 bg-white p-1">
          {TAB_VALUES.map((value) => (
            <button
              key={value}
              type="button"
              onClick={() => setStatus(value)}
              className={`rounded-md px-4 py-1.5 text-sm font-medium transition ${
                status === value
                  ? 'bg-brand-500 text-white'
                  : 'text-slate-500 hover:text-slate-700'
              }`}
            >
              {t(`statusLabel.${value}`)}
            </button>
          ))}
        </div>

        {queue.isLoading ? (
          <SkeletonList />
        ) : queue.isError ? (
          <EmptyState
            title={t('queue.errorTitle')}
            body={
              queue.error instanceof ApiError
                ? queue.error.message
                : t('queue.errorBody')
            }
          />
        ) : results.length > 0 ? (
          <div className="flex flex-col gap-4">
            {results.map((req) => {
              const isThis =
                decision.isPending &&
                decision.variables?.requestId === req.id
              const errThis =
                decision.isError &&
                decision.variables?.requestId === req.id
              return (
                <RequestCard
                  key={req.id}
                  request={req}
                  pending={isThis}
                  error={
                    errThis
                      ? decision.error instanceof ApiError
                        ? decision.error.message
                        : t('queue.updateError')
                      : null
                  }
                  onDecide={(choice) => decideFor(req.id, choice)}
                />
              )
            })}
          </div>
        ) : (
          <EmptyState
            title={t('queue.emptyTitle', { status: t(`status.${status}`) })}
            body={
              status === 'pending'
                ? t('queue.emptyPendingBody')
                : t('queue.emptyOtherBody', { status: t(`status.${status}`) })
            }
          />
        )}

        {queue.isFetching && !queue.isLoading && (
          <div className="mt-4 flex justify-center">
            <Spinner className="size-5 text-brand-500" />
          </div>
        )}
      </main>
    </div>
  )
}

function SkeletonList() {
  return (
    <div className="flex flex-col gap-4">
      {Array.from({ length: 3 }).map((_, i) => (
        <div
          key={i}
          className="animate-pulse rounded-2xl border border-slate-200 bg-white p-5"
        >
          <div className="flex gap-4">
            <div className="size-12 shrink-0 rounded-full bg-slate-200" />
            <div className="flex-1 space-y-2 py-1">
              <div className="h-4 w-40 rounded bg-slate-200" />
              <div className="h-3 w-52 rounded bg-slate-100" />
            </div>
          </div>
          <div className="mt-4 h-9 w-full rounded bg-slate-100" />
        </div>
      ))}
    </div>
  )
}

function EmptyState({ title, body }: { title: string; body: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-slate-300 bg-white py-16 text-center">
      <p className="text-base font-medium text-slate-700">{title}</p>
      <p className="mt-1 text-sm text-slate-500">{body}</p>
    </div>
  )
}
