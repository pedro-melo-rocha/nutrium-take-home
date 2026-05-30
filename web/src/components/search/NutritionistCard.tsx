import { formatDistance, formatDuration, formatPrice } from '../../lib/format'
import type { NutritionistCard as Nutritionist, Service } from '../../lib/types'
import {
  ArrowRightIcon,
  ClockIcon,
  EuroIcon,
  PinIcon,
  StarIcon,
} from '../icons'

interface Props {
  nutritionist: Nutritionist
  onSchedule: (nutritionist: Nutritionist) => void
}

export function NutritionistCard({ nutritionist, onSchedule }: Props) {
  const { name, title, license_number, photo_url, services, distance_km } =
    nutritionist
  const primaryLocation = services[0]?.location

  return (
    <article className="flex flex-col gap-5 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition hover:shadow-md sm:flex-row">
      {/* Identity */}
      <div className="flex gap-4 sm:w-64 sm:shrink-0">
        <Avatar name={name} src={photo_url} />
        <div className="min-w-0">
          <span className="inline-flex items-center gap-1 text-[11px] font-semibold uppercase tracking-wide text-brand-600">
            <StarIcon className="size-3.5" />
            Follow-up
          </span>
          <h3 className="truncate text-lg font-semibold text-brand-700">
            {name}
          </h3>
          <p className="text-sm text-slate-500">
            {[title, license_number].filter(Boolean).join(' · ')}
          </p>
          {(primaryLocation || distance_km != null) && (
            <p className="mt-2 flex items-center gap-1 text-sm text-slate-500">
              <PinIcon className="size-4 text-brand-500" />
              {primaryLocation}
              {distance_km != null && (
                <span className="text-slate-400">
                  · {formatDistance(distance_km)}
                </span>
              )}
            </p>
          )}
        </div>
      </div>

      {/* Services */}
      <ul className="flex flex-1 flex-col gap-2 sm:border-l sm:border-slate-100 sm:pl-5">
        {services.map((s) => (
          <ServiceRow key={s.id} service={s} />
        ))}
      </ul>

      {/* Actions */}
      <div className="flex flex-col gap-2 sm:w-44 sm:shrink-0">
        <button
          type="button"
          onClick={() => onSchedule(nutritionist)}
          className="rounded-lg bg-coral-500 px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-coral-600 active:scale-[0.98]"
        >
          Schedule appointment
        </button>
        <button
          type="button"
          title="Personal page (coming soon)"
          className="inline-flex items-center justify-center gap-1.5 rounded-lg border border-brand-500 px-4 py-2.5 text-sm font-semibold text-brand-600 transition hover:bg-brand-50"
        >
          Personal page
          <ArrowRightIcon className="size-4" />
        </button>
      </div>
    </article>
  )
}

function ServiceRow({ service }: { service: Service }) {
  return (
    <li className="flex flex-wrap items-center gap-x-4 gap-y-1 rounded-lg bg-slate-50 px-3 py-2 text-sm">
      <span className="font-medium text-slate-700">{service.name}</span>
      <span className="flex items-center gap-1 text-slate-500">
        <PinIcon className="size-4 text-slate-400" />
        {service.location}
      </span>
      <span className="flex items-center gap-1 text-slate-500">
        <ClockIcon className="size-4 text-slate-400" />
        {formatDuration(service.duration_minutes)}
      </span>
      <span className="ml-auto flex items-center gap-1 font-semibold text-slate-700">
        <EuroIcon className="size-4 text-brand-500" />
        {formatPrice(service.price_cents)}
      </span>
    </li>
  )
}

function Avatar({ name, src }: { name: string; src: string | null }) {
  const initials = name
    .split(' ')
    .map((p) => p[0])
    .slice(0, 2)
    .join('')
    .toUpperCase()

  if (src) {
    return (
      <img
        src={src}
        alt={name}
        loading="lazy"
        className="size-16 shrink-0 rounded-full object-cover"
      />
    )
  }
  return (
    <div className="grid size-16 shrink-0 place-items-center rounded-full bg-brand-100 text-lg font-semibold text-brand-700">
      {initials}
    </div>
  )
}
