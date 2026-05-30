import { useEffect, useId, type ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { useDecision } from '../../api/appointments'
import { ApiError } from '../../lib/api'
import {
  formatDate,
  formatDuration,
  formatPrice,
  formatTime,
} from '../../lib/format'
import type { AppointmentRequest } from '../../lib/types'
import {
  CalendarIcon,
  CheckIcon,
  ClockIcon,
  CloseIcon,
  EuroIcon,
  PinIcon,
} from '../icons'
import { Spinner } from '../Spinner'

interface Props {
  request: AppointmentRequest
  nutritionistId: string
  onClose: () => void
}

export function AnswerModal({ request, nutritionistId, onClose }: Props) {
  const { t } = useTranslation()
  const titleId = useId()
  const decision = useDecision(nutritionistId)
  const { guest_name, guest_email, starts_at, service } = request

  // Lock body scroll + close on Escape.
  useEffect(() => {
    const prev = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose()
    window.addEventListener('keydown', onKey)
    return () => {
      document.body.style.overflow = prev
      window.removeEventListener('keydown', onKey)
    }
  }, [onClose])

  // The mutation invalidates the queue; close once the decision lands.
  useEffect(() => {
    if (decision.isSuccess) onClose()
  }, [decision.isSuccess, onClose])

  const pending = decision.isPending
  const error = decision.isError
    ? decision.error instanceof ApiError
      ? decision.error.message
      : t('queue.updateError')
    : null

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-slate-900/40 p-0 backdrop-blur-sm sm:items-center sm:p-4"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-md rounded-t-2xl bg-white shadow-xl sm:rounded-2xl"
      >
        <header className="flex items-start justify-between gap-4 border-b border-slate-100 p-5">
          <div>
            <h2 id={titleId} className="text-lg font-semibold text-slate-800">
              {t('request.answerTitle')}
            </h2>
            <p className="text-sm text-slate-500">{guest_name}</p>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label={t('common.close')}
            className="grid size-8 place-items-center rounded-full text-slate-400 transition hover:bg-slate-100 hover:text-slate-600"
          >
            <CloseIcon className="size-5" />
          </button>
        </header>

        <dl className="flex flex-col gap-3 p-5 text-sm">
          <Row label={t('request.email')}>{guest_email}</Row>
          <Row
            label={t('request.when')}
            icon={<CalendarIcon className="size-4 text-brand-500" />}
          >
            {formatDate(starts_at)}
          </Row>
          <Row icon={<ClockIcon className="size-4 text-brand-500" />}>
            {formatTime(starts_at)}
            {service && (
              <span className="text-slate-400">
                {' · '}
                {formatDuration(service.duration_minutes)}
              </span>
            )}
          </Row>
          {service && (
            <>
              <Row label={t('request.service')}>{service.name}</Row>
              <Row icon={<PinIcon className="size-4 text-brand-500" />}>
                {service.location}
              </Row>
              <Row icon={<EuroIcon className="size-4 text-brand-500" />}>
                {formatPrice(service.price_cents)}
              </Row>
            </>
          )}
        </dl>

        {error && (
          <p className="mx-5 mb-2 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">
            {error}
          </p>
        )}

        <div className="flex gap-2 border-t border-slate-100 p-5">
          <button
            type="button"
            disabled={pending}
            onClick={() => decision.mutate({ requestId: request.id, decision: 'accept' })}
            className="inline-flex flex-1 items-center justify-center gap-1.5 rounded-lg bg-brand-500 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-brand-600 disabled:opacity-60"
          >
            {pending ? (
              <Spinner className="size-4" />
            ) : (
              <CheckIcon className="size-4" />
            )}
            {t('request.accept')}
          </button>
          <button
            type="button"
            disabled={pending}
            onClick={() => decision.mutate({ requestId: request.id, decision: 'reject' })}
            className="inline-flex flex-1 items-center justify-center gap-1.5 rounded-lg border border-slate-300 px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50 disabled:opacity-60"
          >
            <CloseIcon className="size-4" />
            {t('request.reject')}
          </button>
        </div>
      </div>
    </div>
  )
}

function Row({
  label,
  icon,
  children,
}: {
  label?: string
  icon?: ReactNode
  children: ReactNode
}) {
  return (
    <div className="flex items-center gap-2 text-slate-600">
      {icon && <span className="shrink-0">{icon}</span>}
      {label && <span className="text-slate-400">{label}:</span>}
      <span>{children}</span>
    </div>
  )
}
