import { Link, useParams } from 'react-router-dom'
import { Logo } from '../components/Logo'

export default function QueuePage() {
  const { id } = useParams()

  return (
    <div className="min-h-screen">
      <header className="bg-white shadow-sm">
        <div className="mx-auto flex max-w-5xl items-center justify-between px-4 py-4">
          <Logo className="text-brand-600" />
          <Link to="/" className="text-sm font-medium text-brand-600">
            ← Back to search
          </Link>
        </div>
      </header>
      <main className="mx-auto max-w-5xl px-4 py-16 text-center">
        <p className="text-base font-medium text-slate-700">
          Pending requests for nutritionist #{id}
        </p>
        <p className="mt-1 text-sm text-slate-500">Coming in Phase 2.</p>
      </main>
    </div>
  )
}
