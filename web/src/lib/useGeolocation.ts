import { useCallback, useState } from 'react'

interface GeoState {
  lat: number
  lng: number
}

interface UseGeolocation {
  coords: GeoState | null
  loading: boolean
  error: string | null
  request: () => void
  clear: () => void
}

export function useGeolocation(): UseGeolocation {
  const [coords, setCoords] = useState<GeoState | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const request = useCallback(() => {
    if (!('geolocation' in navigator)) {
      setError('Geolocation is not supported by this browser.')
      return
    }
    setLoading(true)
    setError(null)
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setCoords({ lat: pos.coords.latitude, lng: pos.coords.longitude })
        setLoading(false)
      },
      (err) => {
        setError(err.message)
        setLoading(false)
      },
      { enableHighAccuracy: false, timeout: 10_000, maximumAge: 60_000 },
    )
  }, [])

  const clear = useCallback(() => {
    setCoords(null)
    setError(null)
  }, [])

  return { coords, loading, error, request, clear }
}
