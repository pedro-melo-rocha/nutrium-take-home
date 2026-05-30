import { createBrowserRouter, Navigate } from 'react-router-dom'
import SearchPage from './pages/SearchPage'
import QueuePage from './pages/QueuePage'

export const router = createBrowserRouter([
  { path: '/', element: <SearchPage /> },
  { path: '/nutritionists/:id/requests', element: <QueuePage /> },
  { path: '*', element: <Navigate to="/" replace /> },
])
