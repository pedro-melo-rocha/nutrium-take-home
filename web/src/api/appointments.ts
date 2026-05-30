import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { apiFetch } from '../lib/api'
import type {
  AppointmentRequest,
  AppointmentStatus,
  LookupResponse,
  QueueResponse,
} from '../lib/types'

export interface CreateAppointmentInput {
  service_id: number
  guest_name: string
  guest_email: string
  starts_at: string
}

export function useCreateAppointment() {
  return useMutation({
    mutationFn: (input: CreateAppointmentInput) =>
      apiFetch<AppointmentRequest>('/api/v1/appointment_requests', {
        method: 'POST',
        body: JSON.stringify({ appointment_request: input }),
      }),
  })
}


export async function lookupGuest(email: string): Promise<LookupResponse> {
  return apiFetch<LookupResponse>(
    `/api/v1/appointment_requests/lookup?guest_email=${encodeURIComponent(email)}`,
  )
}

export function useQueue(
  nutritionistId: string,
  status: AppointmentStatus,
  enabled = true,
) {
  return useQuery({
    queryKey: ['queue', nutritionistId, status],
    enabled: !!nutritionistId && enabled,
    queryFn: () =>
      apiFetch<QueueResponse>(
        `/api/v1/nutritionists/${nutritionistId}/appointment_requests?status=${status}`,
      ),
  })
}

export function useDecision(nutritionistId: string) {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: ({
      requestId,
      decision,
    }: {
      requestId: number
      decision: 'accept' | 'reject'
    }) =>
      apiFetch<AppointmentRequest>(
        `/api/v1/nutritionists/${nutritionistId}/appointment_requests/${requestId}`,
        { method: 'PATCH', body: JSON.stringify({ decision }) },
      ),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['queue', nutritionistId] })
    },
  })
}
