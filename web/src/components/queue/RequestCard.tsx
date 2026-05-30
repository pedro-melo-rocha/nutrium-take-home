import { useTranslation } from 'react-i18next'
import { formatDate, formatTime } from '../../lib/format'
import type { AppointmentRequest } from '../../lib/types'
import { CalendarIcon, ClockIcon } from '../icons'

interface Props {
  request: AppointmentRequest
  onAnswer: () => void
}

export function RequestCard({ request, onAnswer }: Props) {
  const { t } = useTranslation()
  const { guest_name, guest_email, starts_at, service, status } = request
  const isPending = status === 'pending'
  const subtitle = service?.name ?? guest_email

  return (
    <article className="flex flex-col rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div className="flex flex-col gap-4 p-5">
        <div className="flex items-center gap-3">
          <Avatar name={guest_name} />
          <div className="min-w-0">
            <h3 className="truncate font-medium text-slate-700">
              {guest_name}
            </h3>
            <p className="truncate text-sm text-slate-400">{subtitle}</p>
          </div>
        </div>

        <dl className="flex flex-col gap-2 text-sm text-slate-500">
          <div className="flex items-center gap-2">
            <CalendarIcon className="size-4 shrink-0 text-brand-500" />
            <span>{formatDate(starts_at)}</span>
          </div>
          <div className="flex items-center gap-2">
            <ClockIcon className="size-4 shrink-0 text-brand-500" />
            <span>{formatTime(starts_at)}</span>
          </div>
        </dl>
      </div>

      <div className="border-t border-slate-100">
        {isPending ? (
          <button
            type="button"
            onClick={onAnswer}
            className="w-full rounded-b-2xl px-5 py-3.5 text-sm font-semibold text-brand-600 transition hover:bg-brand-50"
          >
            {t('request.answer')}
          </button>
        ) : (
          <div className="flex justify-center px-5 py-3.5">
            <StatusBadge status={status} />
          </div>
        )}
      </div>
    </article>
  )
}

function StatusBadge({ status }: { status: 'accepted' | 'rejected' }) {
  const { t } = useTranslation()
  const styles =
    status === 'accepted'
      ? 'bg-brand-100 text-brand-700'
      : 'bg-slate-100 text-slate-500'
  return (
    <span className={`rounded-full px-3 py-1 text-xs font-semibold ${styles}`}>
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
