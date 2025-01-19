'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'

interface User {
  id: string
  firstName: string
  lastName: string
  email: string
  role: string
}

export default function Dashboard() {
  const [user, setUser] = useState<User | null>(null)
  const router = useRouter()

  useEffect(() => {
    // Verify auth by making API call instead of checking localStorage
    fetch('http://localhost:8080/api/verify', {
      credentials: 'include', // Important for sending cookies
    })
      .then(async (res) => {
        if (!res.ok) throw new Error('Not authenticated')
        const userData = await res.json()
        setUser(userData)
      })
      .catch(() => {
        router.push('/login')
      })
  }, [router])

  if (!user) {
    return <div>Loading...</div>
  }

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">Dashboard</h1>
      
      <div className="bg-white shadow rounded-lg p-6">
        <h2 className="text-xl font-semibold mb-4">Welcome, {user.firstName}!</h2>
        
        <div className="space-y-2">
          <p><span className="font-medium">Name:</span> {user.firstName} {user.lastName}</p>
          <p><span className="font-medium">Email:</span> {user.email}</p>
          <p><span className="font-medium">Role:</span> {user.role}</p>
        </div>
      </div>
    </div>
  )
}
