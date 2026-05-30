import type { ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { formatDate, formatDuration, formatPrice, formatTime } from '../../lib/format'
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
  pending: boolean
  error: string | null
  onDecide: (decision: 'accept' | 'reject') => void
}

export function RequestCard({ request, pending, error, onDecide }: Props) {
  const { t } = useTranslation()
  const { guest_name, guest_email, starts_at, service, status } = request
  const isPending = status === 'pending'

  return (
    <article className="flex flex-col gap-4 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex items-start gap-4">
        <Avatar name={guest_name} />
        <div className="min-w-0 flex-1">
          <h3 className="truncate text-base font-semibold text-slate-800">
            {guest_name}
          </h3>
          <p className="truncate text-sm text-slate-500">{guest_email}</p>
          {service && (
            <p className="mt-0.5 truncate text-sm text-slate-500">
              {service.name}
            </p>
          )}
        </div>
        {!isPending && <StatusBadge status={status} />}
      </div>

      <dl className="flex flex-wrap gap-x-5 gap-y-1.5 text-sm text-slate-600">
        <Meta icon={<CalendarIcon className="size-4 text-brand-500" />}>
          {formatDate(starts_at)}
        </Meta>
        <Meta icon={<ClockIcon className="size-4 text-brand-500" />}>
          {formatTime(starts_at)}
          {service && (
            <span className="text-slate-400">
              {' '}
              · {formatDuration(service.duration_minutes)}
            </span>
          )}
        </Meta>
        {service && (
          <>
            <Meta icon={<PinIcon className="size-4 text-brand-500" />}>
              {service.location}
            </Meta>
            <Meta icon={<EuroIcon className="size-4 text-brand-500" />}>
              {formatPrice(service.price_cents)}
            </Meta>
          </>
        )}
      </dl>

      {error && (
        <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">
          {error}
        </p>
      )}

      {isPending && (
        <div className="flex gap-2 border-t border-slate-100 pt-4">
          <button
            type="button"
            disabled={pending}
            onClick={() => onDecide('accept')}
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
            onClick={() => onDecide('reject')}
            className="inline-flex flex-1 items-center justify-center gap-1.5 rounded-lg border border-slate-300 px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50 disabled:opacity-60"
          >
            <CloseIcon className="size-4" />
            {t('request.reject')}
          </button>
        </div>
      )}
    </article>
  )
}

function Meta({
  icon,
  children,
}: {
  icon: ReactNode
  children: ReactNode
}) {
  return (
    <span className="flex items-center gap-1.5">
      {icon}
      {children}
    </span>
  )
}

function StatusBadge({ status }: { status: 'accepted' | 'rejected' }) {
  const { t } = useTranslation()
  const styles =
    status === 'accepted'
      ? 'bg-brand-100 text-brand-700'
      : 'bg-slate-100 text-slate-500'
  return (
    <span
      className={`shrink-0 rounded-full px-3 py-1 text-xs font-semibold ${styles}`}
    >
      {t(`statusLabel.${status}`)}
    </span>
  )
}

function Avatar({ name }: { name: string }) {
  const initials = name
    .split(' ')
    .map((p) => p[0])
    .slice(0, 2)
    .join('')
    .toUpperCase()
  return (
    <div className="grid size-12 shrink-0 place-items-center rounded-full bg-brand-100 text-sm font-semibold text-brand-700">
      {initials}
    </div>
  )
}
